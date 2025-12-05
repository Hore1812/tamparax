-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 04-12-2025 a las 23:57:37
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `u505676278_inet_ampara`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`127.0.0.1` PROCEDURE `actualizar_planificacion_existente` ()   BEGIN
    -- Parte 1: Corregir registros existentes en detalles_planificacion.
    -- Esto incluye actualizar los datos Y corregir el enlace a la planificación si es incorrecto.
    -- Se busca el plan correcto (p_correcta) basado en la liquidación y se actualiza el detalle.
    UPDATE detalles_planificacion dp
    JOIN liquidacion l ON dp.idliquidacion = l.idliquidacion
    JOIN planificacion p_correcta ON l.idcontratocli = p_correcta.idContratoCliente
                                  AND MONTH(l.fecha) = MONTH(p_correcta.fechaplan)
                                  AND YEAR(l.fecha) = YEAR(p_correcta.fechaplan)
    SET
        dp.Idplanificacion = p_correcta.Idplanificacion, -- Clave: Corrige el enlace al plan correcto
        dp.fechaliquidacion = l.fecha,
        dp.estado = l.estado,
        dp.cantidahoras = l.cantidahoras
    WHERE
        l.activo = 1;

    -- Parte 2: Insertar nuevos detalles para liquidaciones que aún no tienen una entrada.
    -- Esta lógica no cambia, pero ahora es más segura porque la Parte 1 limpió los datos.
    INSERT INTO detalles_planificacion (Idplanificacion, idliquidacion, fechaliquidacion, estado, cantidahoras)
    SELECT
        p.Idplanificacion,
        l.idliquidacion,
        l.fecha,
        l.estado,
        l.cantidahoras
    FROM
        planificacion p
    JOIN
        liquidacion l ON p.idContratoCliente = l.idcontratocli
    LEFT JOIN
        detalles_planificacion dp ON l.idliquidacion = dp.idliquidacion
    WHERE
        MONTH(p.fechaplan) = MONTH(l.fecha)
        AND YEAR(p.fechaplan) = YEAR(l.fecha)
        AND l.activo = 1
        AND dp.idliquidacion IS NULL;

    -- Parte 3: Re-sincronizar la distribución de horas para liquidaciones completas.
    -- Esta lógica no cambia. Se asegura de que las horas se atribuyan correctamente.
    DELETE FROM distribucion_planificacion
    WHERE iddetalle IN (
        SELECT iddetalle
        FROM detalles_planificacion dp
        JOIN liquidacion l ON dp.idliquidacion = l.idliquidacion
        WHERE l.estado = 'Completo'
    );

    INSERT INTO distribucion_planificacion (iddetalle, idparticipante, porcentaje, horas_asignadas)
    SELECT
        dp.iddetalle,
        dh.participante,
        dh.porcentaje,
        dh.calculo
    FROM
        detalles_planificacion dp
    JOIN
        liquidacion l ON dp.idliquidacion = l.idliquidacion
    JOIN
        distribucionhora dh ON l.idliquidacion = dh.idliquidacion
    WHERE
        l.estado = 'Completo';
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `adendacliente`
--

CREATE TABLE `adendacliente` (
  `idadendacli` int(11) NOT NULL,
  `descripcion` varchar(500) NOT NULL,
  `fechainicio` date NOT NULL,
  `fechafin` date NOT NULL,
  `horasfijasmes` int(11) DEFAULT NULL,
  `horasmaxbolsa` int(11) DEFAULT NULL,
  `planhorasfijas` int(11) DEFAULT NULL,
  `comentarios` varchar(500) DEFAULT NULL,
  `idcontratocli` int(11) NOT NULL,
  `costohorafija` decimal(7,2) DEFAULT NULL,
  `mesescontrato` int(11) DEFAULT NULL,
  `totalhorasfijas` int(11) DEFAULT NULL,
  `tipobolsa` varchar(50) DEFAULT NULL,
  `costohoraextra` decimal(7,2) DEFAULT NULL,
  `montofijomes` decimal(7,2) DEFAULT NULL,
  `planmontomes` decimal(7,2) DEFAULT NULL,
  `planhorasextrasmes` int(11) DEFAULT NULL,
  `rutaarchivo` varchar(500) DEFAULT NULL,
  `editor` int(11) NOT NULL,
  `registrado` timestamp NOT NULL DEFAULT current_timestamp(),
  `modificado` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `adendacliente`
--

INSERT INTO `adendacliente` (`idadendacli`, `descripcion`, `fechainicio`, `fechafin`, `horasfijasmes`, `horasmaxbolsa`, `planhorasfijas`, `comentarios`, `idcontratocli`, `costohorafija`, `mesescontrato`, `totalhorasfijas`, `tipobolsa`, `costohoraextra`, `montofijomes`, `planmontomes`, `planhorasextrasmes`, `rutaarchivo`, `editor`, `registrado`, `modificado`) VALUES
(1, 'Adenda 1 CALA', '2023-09-01', '2024-02-29', 8, 2, 10, '', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2025-12-04 15:53:01', '2025-12-04 15:53:01'),
(2, 'Adenda 2 CALA', '2024-03-01', '2025-02-28', 10, 2, 12, '', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2025-12-04 15:53:01', '2025-12-04 15:53:01'),
(3, 'Adenda 1 DOLPHIN', '2024-09-01', '2025-08-31', 10, 0, 10, '', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2025-12-04 15:53:01', '2025-12-04 15:53:01'),
(4, 'Adenda 1 IPT', '2021-08-18', '2022-08-17', 8, 2, 10, '', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2025-12-04 15:53:01', '2025-12-04 15:53:01'),
(5, 'Adenda 2 IPT', '2022-08-18', '2023-08-17', 8, 2, 10, '', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2025-12-04 15:53:01', '2025-12-04 15:53:01'),
(6, 'Adenda 3 IPT', '2023-08-18', '2024-08-31', 10, 2, 12, '', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2025-12-04 15:53:01', '2025-12-04 15:53:01'),
(7, 'Adenda 4 IPT', '2024-09-01', '2025-08-31', 15, 2, 18, '', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2025-12-04 15:53:01', '2025-12-04 15:53:01'),
(8, 'Prueba', '2025-12-04', '2026-01-10', 10, NULL, NULL, 'ok', 11, 100.00, 11, 11, 'Mensual', 110.00, 1000.00, 500.00, 5, 'PDF/adendas/adenda_AMPARA_11_20251204_6931ee5728fab.pdf', 2, '2025-12-04 20:25:59', '2025-12-04 20:34:59'),
(9, 'Prueba 2', '2026-01-10', '2026-01-31', NULL, NULL, NULL, '', 11, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'PDF/adendas/adenda_AMPARA_11_20251204_6931efc722ebc.pdf', 2, '2025-12-04 20:32:07', '2025-12-04 20:32:07');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `adendaempleado`
--

CREATE TABLE `adendaempleado` (
  `idadendaemp` int(11) NOT NULL,
  `descripcion` varchar(500) NOT NULL,
  `fechainicio` date NOT NULL,
  `fechafin` date NOT NULL,
  `salariobruto` decimal(7,2) NOT NULL,
  `costohoraextra` decimal(7,2) NOT NULL,
  `comentarios` varchar(500) NOT NULL,
  `activo` int(11) NOT NULL,
  `idcontratoemp` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `adendaempleado`
--

INSERT INTO `adendaempleado` (`idadendaemp`, `descripcion`, `fechainicio`, `fechafin`, `salariobruto`, `costohoraextra`, `comentarios`, `activo`, `idcontratoemp`) VALUES
(1, 'Adenda 1', '2024-05-07', '2025-04-30', 2000.00, 0.00, '', 0, 2),
(2, 'Adenda 2', '2025-05-01', '2025-10-31', 2200.00, 0.00, '', 0, 2),
(3, 'Adenda 1', '2024-10-01', '2025-09-30', 3000.00, 0.00, '', 0, 3),
(4, 'Adenda 1', '2025-01-03', '2025-07-03', 2500.00, 0.00, '', 0, 4);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `alerta_normativa`
--

CREATE TABLE `alerta_normativa` (
  `id` int(11) NOT NULL,
  `tematica` varchar(250) DEFAULT NULL,
  `entidad` varchar(250) NOT NULL,
  `tipo_norma` varchar(250) NOT NULL,
  `numero_norma` varchar(250) NOT NULL,
  `fecha` date NOT NULL,
  `detalle` text DEFAULT NULL,
  `url` text DEFAULT NULL,
  `editor` int(11) NOT NULL,
  `registrado` timestamp NOT NULL DEFAULT current_timestamp(),
  `modificado` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `alerta_normativa`
--

INSERT INTO `alerta_normativa` (`id`, `tematica`, `entidad`, `tipo_norma`, `numero_norma`, `fecha`, `detalle`, `url`, `editor`, `registrado`, `modificado`) VALUES
(1, NULL, 'MTC', 'RESOLUCION MINISTERIAL', '1254', '2025-11-18', 'ADSFDSGADFGDFG', 'https://ampara.pe/', 2, '2025-11-25 22:00:21', '2025-11-28 00:42:23');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `anuncio`
--

CREATE TABLE `anuncio` (
  `idanuncio` int(11) NOT NULL,
  `fechainicio` date NOT NULL,
  `fechafin` date NOT NULL,
  `rutaarchivo` varchar(500) NOT NULL,
  `comentario` varchar(500) NOT NULL,
  `editor` int(11) NOT NULL,
  `registrado` timestamp NOT NULL DEFAULT current_timestamp(),
  `modificado` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `anuncio`
--

INSERT INTO `anuncio` (`idanuncio`, `fechainicio`, `fechafin`, `rutaarchivo`, `comentario`, `editor`, `registrado`, `modificado`) VALUES
(4, '2025-11-28', '2025-11-30', 'img/anuncios/6929aceb94a2e-PREVIEW - This is how it will look like! (1).png', 'Panilla Fin de Mes', 2, '2025-11-28 14:08:43', '2025-11-28 14:08:43'),
(5, '2025-11-28', '2025-11-28', 'img/anuncios/6929ad50cd204-PREVIEW - This is how it will look like! (2).png', 'Actualización Semanal', 2, '2025-11-28 14:10:24', '2025-11-28 14:10:24'),
(7, '2025-12-03', '2025-12-03', 'img/anuncios/693053eb2dda9-Banner horizontal nueva colección minimalista y tipográfico beige (1).png', 'Agenda Presencial 03 Dic', 2, '2025-12-03 15:14:51', '2025-12-03 15:14:51');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `boletin_regulatorio`
--

CREATE TABLE `boletin_regulatorio` (
  `id` int(11) NOT NULL,
  `anio` year(4) NOT NULL,
  `mes` varchar(20) NOT NULL,
  `asunto` varchar(255) NOT NULL,
  `archivo` varchar(250) NOT NULL,
  `fecha_publicacion` date NOT NULL,
  `fecha_registro` timestamp NOT NULL DEFAULT current_timestamp(),
  `modificado` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `editor` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `calendario`
--

CREATE TABLE `calendario` (
  `idcalendario` int(11) NOT NULL,
  `asunto` varchar(150) NOT NULL,
  `fecha` date NOT NULL,
  `descripcion` varchar(500) NOT NULL,
  `colorfondo` varchar(25) NOT NULL,
  `colortexto` varchar(25) NOT NULL,
  `lider` int(11) NOT NULL,
  `acargode` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cliente`
--

CREATE TABLE `cliente` (
  `idcliente` int(11) NOT NULL,
  `razonsocial` varchar(50) NOT NULL,
  `nombrecomercial` varchar(50) NOT NULL,
  `ruc` varchar(15) NOT NULL,
  `direccion` varchar(150) NOT NULL,
  `telefono` varchar(15) NOT NULL,
  `sitioweb` varchar(150) NOT NULL,
  `representante` varchar(100) NOT NULL,
  `telrepresentante` varchar(15) NOT NULL,
  `correorepre` varchar(150) NOT NULL,
  `gerente` varchar(150) NOT NULL,
  `telgerente` varchar(15) NOT NULL,
  `correogerente` varchar(150) NOT NULL,
  `activo` int(11) NOT NULL DEFAULT 1,
  `editor` int(11) NOT NULL DEFAULT 1,
  `registrado` timestamp NOT NULL DEFAULT current_timestamp(),
  `modificado` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `cliente`
--

INSERT INTO `cliente` (`idcliente`, `razonsocial`, `nombrecomercial`, `ruc`, `direccion`, `telefono`, `sitioweb`, `representante`, `telrepresentante`, `correorepre`, `gerente`, `telgerente`, `correogerente`, `activo`, `editor`, `registrado`, `modificado`) VALUES
(1, 'CALA SERVICIOS INTEGRALES E.I.R.L.', 'CALA', '20606544937', 'Jirón San Diego N° 282, Departamento N° 203 - Surquillo', '923418300', 'https://www.mifibra.pe/', 'Alfredo Araujo', '995887204', 'alfredo.araujo@mifibra.pe', 'Israel Tokashiki Yakibu', '995736334', 'israeltoka@gmail.com', 0, 3, '2025-07-07 12:29:24', '2025-12-02 20:30:11'),
(2, 'DOLPHIN TELECOM DEL PERU S.A.C.', 'DOLPHIN', '20467305931', 'Jirón Preciados N° 149, en el distrito de Santiago de Surco', '951680819', 'https://dolphin.pe/', 'Javier Sánchez', '945119964', 'javier.sanchez@dolphin.pe', 'Fernando Javier Sánchez Benalcazar', '945119964', 'javier.sanchez@dolphin.pe', 1, 1, '2025-07-07 12:29:24', '2025-07-07 12:29:24'),
(3, 'INTERNET PARA TODOS S.A.C.', 'IPT', '20602982174', 'Av. Manuel Olguín N° 325, distrito de Santiago de Surco', '953627291', 'https://www.ipt.pe/', 'Sheyla Rojas', '942495272', 'sheyla.reyes@ipt.pe', 'Teresa Gomes De Almeida', '', 'teresa.gomes@ipt.pe', 1, 1, '2025-07-07 12:29:24', '2025-07-07 12:29:24'),
(4, 'FIBERMAX TELECOM S.A.C.', 'FIBERMAX', '20432857183', 'n Calle Ernesto Diez Canseco N°\r\n236, Oficina N° 403 - Miraflores', '958155646', 'https://www.fibermax.com.pe/', 'Kattya Vega', '934310215', 'kattya.vega@intermax.pe', 'Pedro Luis Esponda Villavicencio', '996591315', 'pedro.esponda@intermax.pe', 1, 1, '2025-07-07 12:29:24', '2025-07-07 12:29:24'),
(5, 'INTERMAX S.A.C.', 'INTERMAX', '20600609239', 'Av. Ricardo Palma 341, Oficina 701, Miraflores, Lima', '(01) 7401000', 'https://intermax.pe/#/', 'Kattya Vega', '934310215', 'kattya.vega@intermax.pe', 'Rafael Ángel Yguey Oshiro', '954848710', 'rafael.yguey@intermax.pe', 1, 1, '2025-07-07 12:29:24', '2025-07-07 12:29:24'),
(6, 'PANGEACO S.A.C.', 'PANGEACO', '20606188511', 'Javier Prado Este N° 444, piso 14, oficinas\r\n1401 - 1402, distrito de San Isidro', '', 'https://pe.linkedin.com/company/pangea-peru', 'Julio Cieza', '952934110', 'julio.cieza@pangeaco.pe', 'Luz Giovanna Piskulich Nevado', '', 'giovanna.piskulich@pangeaco.pe', 1, 1, '2025-07-07 12:29:24', '2025-07-07 12:29:24'),
(7, 'PRISONTEC S.A.C.', 'PRISONTEC', '20563709601', 'n Av. Del Pinar N° 180, Oficina 1004 – Santiago de Surco, Lima', '(01) 2566868', 'https://www.prisontec.com/portalweb/', 'Raiza Hernandez', '959717996', 'raiza.hernandez@prisontec.com', 'Augusto Eduardo Fernández Márquez', '', '', 1, 1, '2025-07-07 12:29:24', '2025-07-07 12:29:24'),
(8, 'URBI PROYECTOS SOCIEDAD ANONIMA CERRADA', 'PUNTO DE ACCESO', '20600796438', 'Calle Carlos Villarán Nro. 140, Urb. Santa Catalina, La Victoria, Lima', '(01) 219 2000', 'https://urbiproyectos.pe/', 'Kazhia Fernandez', '939301984', 'kafernandez@intercorp.com.pe', 'Úrsula Consuelo Sánchez Gamarra', '', 'usanchezg@intercorp.com.pe', 1, 1, '2025-07-07 12:29:24', '2025-07-07 12:29:24'),
(9, 'TELECOM BUSINESS PARTNER S.A.C.', 'AMPARA', '20600282205', 'Calle Mártir Olaya N° 129, Oficina N° 1905, Miraflores', '510 1883', 'ampara.pe', 'Juan Carlos Cornejo Cuzzi', '', '', 'Juan Carlos Cornejo Cuzzi', '', '', 1, 1, '2025-07-07 12:29:24', '2025-07-07 12:29:24'),
(10, 'COLLECTE LOCALISATION SATELLITES PERU S.A.C.', 'CLS', '20418217104', 'Av. Angamos Oeste Nro. 537', '000', '', '', '', '', '', '', '', 1, 3, '2025-12-02 20:36:33', '2025-12-02 20:36:33'),
(11, 'TELECOM BUSINESS PARTNER S.A.C.', 'AMPARA', '20600282205', 'Calle Mártir Olaya N° 129, Oficina N° 1905, Miraflores', '(01) 510 1883', '', 'Juan Carlos Cornejo', '', '', 'Gino Kou', '', '', 0, 3, '2025-12-04 16:58:59', '2025-12-04 17:00:11');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `contratocliente`
--

CREATE TABLE `contratocliente` (
  `idcontratocli` int(11) NOT NULL,
  `idcliente` int(11) NOT NULL,
  `lider` int(11) NOT NULL,
  `descripcion` varchar(500) NOT NULL,
  `fechainicio` date NOT NULL,
  `fechafin` date DEFAULT NULL,
  `horasfijasmes` int(11) NOT NULL,
  `costohorafija` decimal(7,2) NOT NULL,
  `mesescontrato` int(11) NOT NULL,
  `totalhorasfijas` int(11) NOT NULL,
  `tipobolsa` varchar(50) NOT NULL,
  `costohoraextra` decimal(7,2) NOT NULL,
  `montofijomes` decimal(7,2) NOT NULL,
  `planmontomes` decimal(7,2) NOT NULL,
  `planhoraextrames` int(11) NOT NULL,
  `status` varchar(50) NOT NULL,
  `tipohora` varchar(500) NOT NULL,
  `activo` int(11) NOT NULL,
  `ruta_pdf_contrato` varchar(255) DEFAULT NULL,
  `editor` int(11) NOT NULL DEFAULT 1,
  `registrado` timestamp NOT NULL DEFAULT current_timestamp(),
  `modificado` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `contratocliente`
--

INSERT INTO `contratocliente` (`idcontratocli`, `idcliente`, `lider`, `descripcion`, `fechainicio`, `fechafin`, `horasfijasmes`, `costohorafija`, `mesescontrato`, `totalhorasfijas`, `tipobolsa`, `costohoraextra`, `montofijomes`, `planmontomes`, `planhoraextrames`, `status`, `tipohora`, `activo`, `ruta_pdf_contrato`, `editor`, `registrado`, `modificado`) VALUES
(1, 1, 4, 'Contrato Principal CALA', '2022-09-01', '2023-08-31', 8, 425.00, 12, 96, 'Mensual', 440.00, 3400.00, 4280.00, 2, 'Vigente', 'Soporte', 0, NULL, 2, '2025-07-07 12:35:05', '2025-08-13 12:41:01'),
(2, 2, 12, 'Contrato Principal DOLPHIN', '2023-09-01', '2024-08-31', 10, 500.00, 12, 120, 'Anual', 550.00, 5000.00, 5000.00, 0, 'Vigente', 'Soporte', 1, NULL, 2, '2025-07-07 12:35:05', '2025-10-06 17:09:40'),
(3, 3, 12, 'Contrato Principal IPT', '2020-08-14', '2021-08-17', 3, 350.00, 12, 36, 'Mensual', 420.00, 1050.00, 1890.00, 2, 'Vigente', 'Soporte', 1, NULL, 2, '2025-07-07 12:35:05', '2025-12-02 20:38:02'),
(4, 4, 3, 'Contrato Principal Fibermax', '2022-01-01', '2023-12-31', 8, 430.00, 24, 192, 'Mensual', 460.00, 3440.00, 4360.00, 2, 'Vigente', 'Soporte', 1, NULL, 2, '2025-07-07 12:35:05', '2025-08-13 12:42:45'),
(5, 5, 3, 'Contrato Principal Intermax', '2022-02-01', '2024-01-31', 20, 306.00, 24, 480, 'Mensual', 460.00, 6120.00, 7040.00, 2, 'Vigente', 'Soporte', 1, NULL, 1, '2025-07-07 12:35:05', '2025-07-07 12:35:05'),
(6, 6, 4, 'Contrato Principal PangeaCo', '2022-07-01', '2022-12-30', 8, 435.00, 6, 48, 'Mensual', 460.00, 3480.00, 4400.00, 2, 'Vigente', 'Soporte', 1, NULL, 1, '2025-07-07 12:35:05', '2025-07-07 12:35:05'),
(8, 7, 4, 'Contrato Principal Prisontec', '2021-02-01', '2022-01-31', 10, 435.00, 12, 120, 'Mensual', 460.00, 4350.00, 5270.00, 2, 'Vigente', 'Soporte', 1, NULL, 1, '2025-07-07 12:35:05', '2025-07-07 12:35:05'),
(9, 8, 12, 'Contrato Principal Punto de Acceso', '2024-08-29', '2024-12-02', 3, 500.00, 3, 9, 'Mensual', 530.00, 1500.00, 3090.00, 3, 'Vigente', 'Soporte', 1, NULL, 2, '2025-07-07 12:35:05', '2025-10-06 17:08:46'),
(10, 5, 3, 'Contrato No Soporte Intermax', '2025-02-19', '2025-11-30', 20, 0.00, 12, 240, '', 0.00, 0.00, 0.00, 0, 'Vigente', 'No Soporte', 1, NULL, 2, '2025-07-07 12:35:05', '2025-12-04 20:41:08'),
(11, 9, 2, 'Prueba', '2015-04-09', '2025-12-31', 1, 0.00, 1, 1, '', 0.00, 0.00, 0.00, 0, 'Vigente', 'Horas internas', 1, 'PDF/contratos/contrato_AMPARA_20251202.pdf', 2, '2025-07-07 12:35:05', '2025-12-04 20:42:15');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `contratoempleado`
--

CREATE TABLE `contratoempleado` (
  `idcontratoemp` int(11) NOT NULL,
  `descripcion` varchar(500) NOT NULL,
  `fechainicio` date NOT NULL,
  `fechafin` date NOT NULL,
  `modalidad` varchar(50) NOT NULL,
  `status` varchar(50) NOT NULL,
  `salariobruto` decimal(7,2) NOT NULL,
  `entidadbancaria` varchar(50) NOT NULL,
  `tipocuenta` varchar(50) NOT NULL,
  `numcuenta1` varchar(50) NOT NULL,
  `numcuenta2` varchar(50) NOT NULL,
  `comentario` varchar(500) NOT NULL,
  `direccion` varchar(50) NOT NULL,
  `area` varchar(50) NOT NULL,
  `puesto` varchar(50) NOT NULL,
  `activo` int(11) NOT NULL,
  `idemp` int(11) NOT NULL,
  `editor` int(11) NOT NULL DEFAULT 3,
  `registrado` timestamp NOT NULL DEFAULT current_timestamp(),
  `modificado` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `contratoempleado`
--

INSERT INTO `contratoempleado` (`idcontratoemp`, `descripcion`, `fechainicio`, `fechafin`, `modalidad`, `status`, `salariobruto`, `entidadbancaria`, `tipocuenta`, `numcuenta1`, `numcuenta2`, `comentario`, `direccion`, `area`, `puesto`, `activo`, `idemp`, `editor`, `registrado`, `modificado`) VALUES
(1, 'Contrato', '2023-02-01', '0000-00-00', 'Planilla', 'Vencido', 2500.00, 'BCP', 'Sueldo', '19199750519098', '', '', 'Operaciones', 'Legal Regulatorio', 'Asociado Ejecutivo', 0, 1, 3, '2025-08-16 11:41:10', '2025-08-16 11:41:10'),
(2, 'Contrato', '2023-11-07', '0000-00-00', 'Planilla', 'Vencido', 1800.00, 'BCP', 'Sueldo', '19300202613059', '', '', 'Administrativo', 'Recursos Humanos', 'Asistente', 0, 2, 3, '2025-08-16 11:41:10', '2025-08-16 11:41:10'),
(3, 'Contrato', '2024-04-03', '0000-00-00', 'Planilla', 'Vencido', 2500.00, 'BCP', 'Sueldo', '19199848053016', '', '', 'Operaciones', 'Técnico Regulatorio', 'Asociado Ejecutivo', 0, 3, 3, '2025-08-16 11:41:10', '2025-08-16 11:41:10'),
(4, 'Contrato', '2024-07-04', '0000-00-00', 'Planilla', 'Vencido', 2500.00, 'BCP', 'Sueldo', '19195006197053', '', '', 'Operaciones', 'Legal Regulatorio', 'Asociado Ejecutivo', 0, 4, 3, '2025-08-16 11:41:10', '2025-08-16 11:41:10'),
(5, 'Contrato', '2025-02-11', '0000-00-00', 'Planilla', 'Vigente', 2500.00, 'IBK', 'Sueldo', '00389801345860304042', '', '', 'Operaciones', 'Legal Regulatorio', 'Asociado Ejecutivo', 0, 5, 3, '2025-08-16 11:41:10', '2025-08-16 11:41:10'),
(6, 'Contrato', '2025-02-17', '0000-00-00', 'Planilla', 'Vigente', 3000.00, 'BCP', 'Sueldo', '19105393963046', '', '', 'Operaciones', 'Legal Regulatorio', 'Asociado Ejecutivo', 0, 6, 3, '2025-08-16 11:41:10', '2025-08-16 11:41:10'),
(7, 'Contrato', '2025-02-26', '0000-00-00', 'Planilla', 'Vigente', 2800.00, 'SCTBK', 'Sueldo', '00914220952002488718', '', '', 'Operaciones', 'Técnico Regulatorio', 'Asociado Ejecutivo', 0, 7, 3, '2025-08-16 11:41:10', '2025-08-16 11:41:10'),
(8, 'Contrato', '2015-04-08', '0000-00-00', 'Recibo por Honorarios', '', 8913.04, 'BCP', 'Ahorros', '19199020334038', '', 'Sueldo neto original 8.2k', 'Socios', 'Legal Regulatorio', 'Socio Fundador', 0, 8, 3, '2025-08-16 11:41:10', '2025-08-16 11:41:10'),
(9, 'Contrato', '2015-04-08', '0000-00-00', 'Recibo por Honorarios', '', 8913.04, 'IBK', 'Ahorros', '00336801309344242488', '', 'Sueldo neto original 8.2k', 'Socios', 'Técnico Regulatorio', 'Socio Fundador', 0, 9, 3, '2025-08-16 11:41:10', '2025-08-16 11:41:10'),
(10, 'Contrato', '0000-00-00', '0000-00-00', '', '', 500.00, 'BCP', 'Ahorros', '19431468626089', '', '', 'Administrativo', 'Contabilidad', 'Locador de Servicios', 0, 10, 3, '2025-08-16 11:41:10', '2025-08-16 11:41:10');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cuotahito`
--

CREATE TABLE `cuotahito` (
  `idcouta` int(11) NOT NULL,
  `fecha` date NOT NULL,
  `descripcion` varchar(500) NOT NULL,
  `hito` varchar(500) NOT NULL,
  `avance` varchar(500) NOT NULL,
  `cuota` decimal(7,2) NOT NULL,
  `idpresupuesto` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalle`
--

CREATE TABLE `detalle` (
  `idetalle` int(11) NOT NULL,
  `idfacturacion` int(11) NOT NULL,
  `tiposervicio` varchar(50) NOT NULL,
  `descripcion` varchar(500) NOT NULL,
  `cantidad` int(11) NOT NULL,
  `precio` decimal(7,2) NOT NULL,
  `importe` decimal(7,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalles_planificacion`
--

CREATE TABLE `detalles_planificacion` (
  `iddetalle` int(11) NOT NULL,
  `Idplanificacion` int(11) NOT NULL,
  `idliquidacion` int(11) NOT NULL,
  `fechaliquidacion` date NOT NULL,
  `estado` varchar(50) NOT NULL,
  `cantidahoras` int(11) NOT NULL,
  `registrado` timestamp NOT NULL DEFAULT current_timestamp(),
  `modificado` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `detalles_planificacion`
--

INSERT INTO `detalles_planificacion` (`iddetalle`, `Idplanificacion`, `idliquidacion`, `fechaliquidacion`, `estado`, `cantidahoras`, `registrado`, `modificado`) VALUES
(1, 1, 4, '2025-05-02', 'Completo', 2, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(2, 1, 5, '2025-05-13', 'Completo', 2, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(3, 1, 6, '2025-05-30', 'Completo', 1, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(4, 2, 12, '2025-05-06', 'Completo', 1, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(5, 2, 15, '2025-05-09', 'Completo', 3, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(6, 2, 16, '2025-05-09', 'Completo', 2, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(7, 2, 17, '2025-05-09', 'Completo', 4, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(8, 2, 18, '2025-05-13', 'Completo', 9, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(9, 2, 19, '2025-05-16', 'Completo', 2, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(10, 2, 21, '2025-05-23', 'Completo', 1, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(11, 2, 23, '2025-05-28', 'Completo', 2, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(12, 2, 26, '2025-05-30', 'Completo', 2, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(13, 3, 13, '2025-05-07', 'Completo', 1, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(14, 3, 14, '2025-05-09', 'Completo', 1, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(15, 3, 20, '2025-05-23', 'Completo', 4, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(16, 3, 22, '2025-05-26', 'Completo', 3, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(17, 3, 25, '2025-05-30', 'Completo', 2, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(18, 4, 7, '2025-05-16', 'Completo', 1, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(19, 4, 8, '2025-05-23', 'Completo', 5, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(20, 4, 9, '2025-05-27', 'Completo', 2, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(21, 4, 10, '2025-05-29', 'Completo', 1, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(22, 4, 11, '2025-05-29', 'Completo', 1, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(23, 5, 32, '2025-07-02', 'Completo', 1, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(24, 5, 37, '2025-07-07', 'Completo', 1, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(25, 5, 46, '2025-07-07', 'Completo', 4, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(26, 5, 53, '2025-07-08', 'Completo', 2, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(27, 5, 54, '2025-07-09', 'Completo', 3, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(28, 5, 57, '2025-07-08', 'Completo', 1, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(29, 5, 64, '2025-07-10', 'Completo', 2, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(30, 5, 70, '2025-07-31', 'Completo', 2, '2025-07-18 12:15:54', '2025-07-31 20:46:08'),
(31, 5, 73, '2025-07-24', 'Completo', 2, '2025-07-18 12:15:54', '2025-07-30 17:27:27'),
(32, 5, 74, '2025-07-24', 'Completo', 4, '2025-07-18 12:15:54', '2025-07-24 18:57:47'),
(33, 6, 47, '2025-07-24', 'Completo', 2, '2025-07-18 12:15:54', '2025-07-24 19:01:36'),
(34, 6, 48, '2025-07-16', 'Completo', 3, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(35, 6, 49, '2025-07-09', 'Completo', 2, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(36, 6, 55, '2025-07-31', 'Completo', 1, '2025-07-18 12:15:54', '2025-07-31 20:51:53'),
(37, 15, 69, '2025-08-05', 'Completo', 3, '2025-07-18 12:15:54', '2025-08-13 22:37:01'),
(38, 6, 72, '2025-07-18', 'Completo', 1, '2025-07-18 12:15:54', '2025-07-19 06:46:21'),
(39, 7, 38, '2025-07-07', 'Completo', 1, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(40, 7, 68, '2025-07-15', 'Completo', 4, '2025-07-18 12:15:54', '2025-07-21 22:24:14'),
(41, 7, 71, '2025-07-21', 'Completo', 3, '2025-07-18 12:15:54', '2025-07-30 19:06:17'),
(42, 8, 36, '2025-07-03', 'Completo', 4, '2025-07-18 12:15:54', '2025-07-25 21:52:41'),
(43, 8, 44, '2025-07-08', 'Completo', 4, '2025-07-18 12:15:54', '2025-07-31 15:20:44'),
(44, 8, 67, '2025-07-18', 'Completo', 4, '2025-07-18 12:15:54', '2025-07-25 21:51:53'),
(45, 9, 66, '2025-07-11', 'Completo', 3, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(46, 10, 24, '2025-07-04', 'Completo', 2, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(47, 10, 30, '2025-07-02', 'Completo', 4, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(48, 10, 40, '2025-07-04', 'Completo', 1, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(49, 10, 42, '2025-07-31', 'Completo', 3, '2025-07-18 12:15:54', '2025-07-31 21:22:47'),
(50, 10, 58, '2025-07-10', 'Completo', 2, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(51, 10, 59, '2025-07-10', 'Completo', 2, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(52, 10, 62, '2025-07-11', 'Completo', 1, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(53, 10, 63, '2025-07-25', 'Completo', 2, '2025-07-18 12:15:54', '2025-07-25 19:33:36'),
(54, 10, 65, '2025-07-11', 'Completo', 3, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(55, 11, 33, '2025-07-02', 'Completo', 1, '2025-07-18 12:15:54', '2025-07-25 21:53:44'),
(56, 11, 35, '2025-07-02', 'Completo', 3, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(57, 11, 39, '2025-07-04', 'Completo', 1, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(58, 11, 45, '2025-07-17', 'Completo', 1, '2025-07-18 12:15:54', '2025-07-31 23:21:07'),
(59, 11, 52, '2025-07-07', 'Completo', 4, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(60, 11, 60, '2025-07-09', 'Completo', 1, '2025-07-18 12:15:54', '2025-07-25 21:55:26'),
(61, 11, 61, '2025-07-09', 'Completo', 1, '2025-07-18 12:15:54', '2025-07-25 21:56:10'),
(62, 12, 31, '2025-07-02', 'Completo', 2, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(63, 12, 41, '2025-07-03', 'Completo', 2, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(64, 12, 75, '2025-07-25', 'Completo', 4, '2025-07-18 12:15:54', '2025-07-25 23:43:23'),
(65, 13, 43, '2025-07-08', 'Completo', 3, '2025-07-18 12:15:54', '2025-08-01 17:34:07'),
(66, 13, 51, '2025-07-08', 'Completo', 3, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(67, 13, 56, '2025-07-08', 'Completo', 3, '2025-07-18 12:15:54', '2025-07-18 12:15:54'),
(128, 17, 76, '2025-08-18', 'Completo', 5, '2025-07-19 06:42:50', '2025-09-01 00:19:20'),
(129, 10, 78, '2025-07-21', 'Completo', 4, '2025-07-21 13:29:30', '2025-07-25 19:19:16'),
(130, 10, 79, '2025-07-22', 'Completo', 4, '2025-07-21 13:31:19', '2025-07-25 19:22:20'),
(131, 10, 80, '2025-07-25', 'Completo', 2, '2025-07-21 13:47:22', '2025-07-31 21:01:08'),
(133, 10, 82, '2025-07-18', 'Completo', 1, '2025-07-21 14:00:25', '2025-07-21 14:00:25'),
(134, 11, 83, '2025-07-18', 'Completo', 4, '2025-07-21 14:08:01', '2025-07-21 15:41:29'),
(135, 8, 84, '2025-07-21', 'Completo', 1, '2025-07-21 14:30:31', '2025-07-22 15:39:14'),
(136, 6, 85, '2025-07-18', 'Completo', 2, '2025-07-21 15:23:40', '2025-07-21 15:23:40'),
(138, 8, 87, '2025-07-22', 'Completo', 1, '2025-07-22 15:38:29', '2025-07-31 21:55:15'),
(139, 14, 77, '2025-07-21', 'Completo', 3, '2025-07-23 00:50:01', '2025-08-01 18:52:25'),
(140, 5, 88, '2025-07-24', 'Completo', 2, '2025-07-24 03:25:18', '2025-07-24 18:59:26'),
(141, 7, 89, '2025-07-30', 'Completo', 3, '2025-07-24 03:29:08', '2025-07-31 21:04:39'),
(142, 11, 90, '2025-07-24', 'Completo', 1, '2025-07-24 16:57:02', '2025-07-24 16:57:02'),
(143, 13, 91, '2025-07-22', 'Completo', 3, '2025-07-25 20:02:37', '2025-07-25 20:02:37'),
(144, 8, 93, '2025-07-31', 'Completo', 3, '2025-07-31 15:13:13', '2025-08-01 18:36:17'),
(145, 10, 94, '2025-08-08', 'Anulado', 4, '2025-07-31 15:16:09', '2025-09-01 15:38:18'),
(146, 10, 95, '2025-07-31', 'Completo', 2, '2025-07-31 15:17:26', '2025-07-31 15:17:26'),
(147, 12, 97, '2025-07-31', 'Completo', 1, '2025-07-31 22:59:43', '2025-08-01 17:49:02'),
(148, 8, 98, '2025-07-30', 'Completo', 1, '2025-07-31 23:19:21', '2025-08-01 17:45:51'),
(149, 14, 100, '2025-07-31', 'Completo', 1, '2025-08-01 18:40:51', '2025-08-01 18:40:51'),
(150, 15, 99, '2025-08-01', 'Completo', 3, '2025-08-08 16:18:55', '2025-08-08 16:18:55'),
(151, 15, 109, '2025-08-07', 'Completo', 1, '2025-08-08 21:43:26', '2025-08-08 21:43:26'),
(153, 15, 113, '2025-08-12', 'Completo', 2, '2025-08-13 15:25:14', '2025-08-15 21:27:21'),
(154, 16, 114, '2025-08-13', 'Completo', 1, '2025-08-13 16:54:27', '2025-08-13 16:54:27'),
(155, 16, 101, '2025-08-31', 'Completo', 2, '2025-08-13 22:37:01', '2025-09-01 14:48:47'),
(156, 16, 102, '2025-08-27', 'Completo', 4, '2025-08-13 22:37:01', '2025-08-26 20:58:48'),
(157, 16, 103, '2025-08-07', 'Completo', 3, '2025-08-13 22:37:01', '2025-08-13 22:37:01'),
(158, 16, 104, '2025-08-05', 'Completo', 4, '2025-08-13 22:37:01', '2025-08-13 22:37:01'),
(159, 16, 108, '2025-08-08', 'Completo', 5, '2025-08-13 22:37:01', '2025-08-13 22:37:01'),
(160, 16, 111, '2025-08-12', 'Completo', 3, '2025-08-13 22:37:01', '2025-08-13 22:37:01'),
(161, 18, 105, '2025-08-04', 'Completo', 4, '2025-08-13 22:37:01', '2025-08-13 22:37:01'),
(162, 20, 110, '2025-08-11', 'Completo', 1, '2025-08-13 22:37:01', '2025-08-13 22:37:01'),
(163, 23, 107, '2025-08-07', 'Completo', 4, '2025-08-13 22:37:01', '2025-08-13 22:37:01'),
(170, 15, 115, '2025-08-14', 'Completo', 1, '2025-08-14 17:30:50', '2025-08-14 17:30:50'),
(171, 20, 116, '2025-08-15', 'Completo', 1, '2025-08-15 22:45:18', '2025-08-16 06:31:12'),
(172, 19, 117, '2025-08-15', 'Completo', 2, '2025-08-15 23:57:31', '2025-08-25 14:54:39'),
(173, 16, 118, '2025-08-15', 'Completo', 1, '2025-08-16 00:05:19', '2025-09-25 21:08:48'),
(174, 17, 119, '2025-08-15', 'Completo', 1, '2025-08-16 01:24:51', '2025-09-01 23:53:44'),
(175, 16, 120, '2025-08-26', 'Completo', 3, '2025-08-18 21:55:53', '2025-08-28 15:18:41'),
(176, 21, 121, '2025-08-20', 'Completo', 1, '2025-08-18 22:01:43', '2025-09-01 23:50:16'),
(177, 20, 122, '2025-08-18', 'Completo', 4, '2025-08-19 20:12:00', '2025-08-19 20:12:00'),
(178, 18, 123, '2025-08-21', 'Completo', 2, '2025-08-19 20:19:54', '2025-08-22 14:13:22'),
(179, 17, 124, '2025-08-26', 'Completo', 5, '2025-08-21 19:15:59', '2025-08-30 06:40:55'),
(180, 17, 125, '2025-08-20', 'Completo', 1, '2025-08-21 19:31:11', '2025-08-29 01:36:53'),
(181, 25, 126, '2025-09-08', 'Completo', 12, '2025-08-21 21:52:20', '2025-09-25 21:08:48'),
(182, 18, 127, '2025-08-21', 'Completo', 1, '2025-08-22 14:00:09', '2025-08-22 14:05:08'),
(184, 26, 129, '2025-09-15', 'Completo', 5, '2025-08-22 17:38:56', '2025-09-25 21:08:48'),
(185, 16, 130, '2025-08-27', 'Anulado', 2, '2025-08-25 13:33:40', '2025-09-01 15:39:09'),
(186, 26, 131, '2025-10-31', 'Anulado', 1, '2025-08-25 13:35:27', '2025-10-31 16:45:02'),
(187, 16, 132, '2025-08-25', 'Anulado', 1, '2025-08-25 13:36:34', '2025-09-01 15:39:04'),
(188, 23, 133, '2025-08-29', 'Completo', 15, '2025-08-25 14:05:54', '2025-08-29 14:07:10'),
(189, 23, 134, '2025-08-27', 'Completo', 20, '2025-08-25 14:07:20', '2025-08-29 14:06:40'),
(190, 29, 135, '2025-09-10', 'Completo', 2, '2025-08-25 14:16:00', '2025-09-25 21:08:48'),
(191, 17, 136, '2025-08-31', 'Completo', 3, '2025-08-25 14:19:45', '2025-08-31 23:50:55'),
(192, 19, 137, '2025-08-15', 'Completo', 2, '2025-08-25 14:58:34', '2025-08-25 14:58:34'),
(193, 19, 138, '2025-08-25', 'Completo', 1, '2025-08-25 15:07:39', '2025-08-26 20:55:43'),
(194, 17, 139, '2025-08-29', 'Completo', 4, '2025-08-29 00:52:04', '2025-08-30 06:32:18'),
(195, 15, 140, '2025-08-27', 'Completo', 3, '2025-08-29 01:07:40', '2025-08-29 01:07:40'),
(196, 18, 141, '2025-08-29', 'Completo', 1, '2025-08-29 14:44:48', '2025-08-29 14:44:48'),
(197, 23, 142, '2025-08-29', 'Completo', 1, '2025-08-29 16:54:50', '2025-08-29 16:54:50'),
(198, 16, 143, '2025-08-29', 'Completo', 2, '2025-08-29 18:02:06', '2025-08-29 18:02:06'),
(199, 15, 144, '2025-08-29', 'Completo', 2, '2025-08-29 21:24:40', '2025-08-29 21:24:40'),
(200, 16, 106, '2025-08-07', 'Anulado', 1, '2025-09-01 15:38:05', '2025-09-01 15:38:05'),
(201, 28, 145, '2025-09-01', 'Completo', 2, '2025-09-25 21:08:48', '2025-09-25 21:08:48'),
(202, 28, 146, '2025-09-04', 'Completo', 3, '2025-09-25 21:08:48', '2025-09-25 21:08:48'),
(203, 29, 147, '2025-09-17', 'Completo', 7, '2025-09-25 21:08:48', '2025-09-25 21:08:48'),
(204, 35, 148, '2025-10-22', 'Completo', 2, '2025-09-25 21:08:48', '2025-11-21 21:31:03'),
(205, 25, 149, '2025-09-01', 'Completo', 2, '2025-09-25 21:08:48', '2025-09-25 21:08:48'),
(206, 25, 150, '2025-09-04', 'Completo', 1, '2025-09-25 21:08:48', '2025-09-25 21:08:48'),
(207, 26, 151, '2025-09-30', 'Completo', 3, '2025-09-25 21:08:48', '2025-09-30 19:23:56'),
(208, 26, 152, '2025-09-15', 'Completo', 3, '2025-09-25 21:08:48', '2025-09-25 21:08:48'),
(209, 28, 153, '2025-09-08', 'Completo', 2, '2025-09-25 21:08:48', '2025-09-25 21:08:48'),
(210, 28, 154, '2025-10-27', 'Anulado', 1, '2025-09-25 21:08:48', '2025-10-27 14:32:28'),
(211, 25, 155, '2025-09-30', 'Completo', 1, '2025-09-25 21:08:48', '2025-09-30 19:28:24'),
(212, 30, 156, '2025-09-03', 'Completo', 2, '2025-09-25 21:08:48', '2025-09-25 21:08:48'),
(213, 28, 157, '2025-09-02', 'Completo', 1, '2025-09-25 21:08:48', '2025-09-25 21:08:48'),
(214, 28, 158, '2025-09-30', 'Completo', 4, '2025-09-25 21:08:48', '2025-09-30 20:59:04'),
(215, 26, 163, '2025-09-15', 'Completo', 3, '2025-09-25 21:08:48', '2025-09-25 21:08:48'),
(217, 43, 165, '2025-11-13', 'Completo', 4, '2025-09-25 21:08:48', '2025-11-21 21:31:03'),
(218, 24, 166, '2025-09-30', 'Completo', 2, '2025-09-25 21:08:48', '2025-09-30 20:47:01'),
(219, 24, 167, '2025-09-05', 'Completo', 2, '2025-09-25 21:08:48', '2025-09-25 21:08:48'),
(220, 30, 168, '2025-09-10', 'Completo', 1, '2025-09-25 21:08:48', '2025-09-25 21:08:48'),
(221, 28, 169, '2025-09-10', 'Completo', 1, '2025-09-25 21:08:48', '2025-09-25 21:08:48'),
(222, 28, 170, '2025-09-11', 'Completo', 1, '2025-09-25 21:08:48', '2025-09-25 21:08:48'),
(223, 38, 171, '2025-10-15', 'Completo', 3, '2025-09-25 21:08:48', '2025-11-21 21:31:03'),
(224, 28, 172, '2025-09-22', 'Completo', 1, '2025-09-25 21:08:48', '2025-09-25 21:08:48'),
(225, 29, 173, '2025-09-15', 'Completo', 2, '2025-09-25 21:08:48', '2025-09-25 21:08:48'),
(226, 28, 174, '2025-09-16', 'Completo', 2, '2025-09-25 21:08:48', '2025-09-25 21:08:48'),
(227, 28, 175, '2025-09-19', 'Completo', 1, '2025-09-25 21:08:48', '2025-09-25 21:08:48'),
(228, 29, 176, '2025-09-18', 'Completo', 1, '2025-09-25 21:08:48', '2025-09-25 21:08:48'),
(229, 26, 177, '2025-09-19', 'Completo', 1, '2025-09-25 21:08:48', '2025-09-25 21:08:48'),
(230, 28, 178, '2025-09-26', 'Completo', 2, '2025-09-25 21:08:48', '2025-09-29 18:32:54'),
(231, 27, 179, '2025-09-19', 'Completo', 7, '2025-09-25 21:08:48', '2025-09-25 21:08:48'),
(232, 27, 180, '2025-09-30', 'Completo', 1, '2025-09-25 21:08:48', '2025-09-30 19:30:02'),
(234, 26, 182, '2025-09-23', 'Completo', 2, '2025-09-25 21:08:48', '2025-09-25 21:08:48'),
(235, 35, 183, '2025-10-06', 'Completo', 2, '2025-09-25 21:08:48', '2025-11-21 21:31:03'),
(236, 34, 184, '2025-10-07', 'Completo', 2, '2025-09-25 21:08:48', '2025-11-21 21:31:03'),
(237, 26, 185, '2025-09-23', 'Completo', 1, '2025-09-25 21:08:48', '2025-09-25 21:08:48'),
(238, 26, 186, '2025-09-26', 'Completo', 8, '2025-09-25 21:08:48', '2025-09-29 13:37:27'),
(239, 24, 187, '2025-09-30', 'Completo', 6, '2025-09-25 21:08:48', '2025-10-01 00:36:12'),
(240, 27, 188, '2025-09-23', 'Completo', 1, '2025-09-25 21:08:48', '2025-09-25 21:08:48'),
(241, 29, 189, '2025-09-23', 'Completo', 1, '2025-09-25 21:08:48', '2025-09-25 21:08:48'),
(242, 27, 190, '2025-09-23', 'Completo', 1, '2025-09-25 21:08:48', '2025-09-25 21:08:48'),
(243, 26, 191, '2025-09-24', 'Completo', 1, '2025-09-25 21:08:48', '2025-09-25 21:08:48'),
(264, 31, 192, '2025-09-26', 'Completo', 1, '2025-09-26 23:18:46', '2025-09-26 23:18:46'),
(265, 38, 193, '2025-10-14', 'Completo', 3, '2025-09-26 23:22:23', '2025-11-21 21:31:03'),
(266, 34, 194, '2025-10-03', 'Completo', 3, '2025-09-29 13:36:37', '2025-11-21 21:31:03'),
(267, 31, 195, '2025-09-30', 'Completo', 3, '2025-09-29 18:59:22', '2025-09-29 18:59:22'),
(268, 26, 196, '2025-09-30', 'Completo', 1, '2025-09-30 19:27:23', '2025-09-30 19:27:23'),
(269, 24, 197, '2025-09-29', 'Completo', 1, '2025-09-30 19:42:21', '2025-09-30 19:42:21'),
(270, 31, 162, '2025-09-22', 'Completo', 2, '2025-10-01 08:10:05', '2025-10-01 08:10:05'),
(271, 31, 160, '2025-09-02', 'Completo', 3, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(272, 31, 161, '2025-09-05', 'Completo', 3, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(273, 36, 198, '2025-10-02', 'Completo', 1, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(274, 36, 199, '2025-10-03', 'Completo', 1, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(275, 36, 200, '2025-10-14', 'Completo', 1, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(276, 33, 201, '2025-10-02', 'Completo', 3, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(277, 35, 202, '2025-10-31', 'Completo', 2, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(278, 39, 203, '2025-10-02', 'Completo', 1, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(279, 32, 204, '2025-10-03', 'Completo', 1, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(280, 38, 205, '2025-10-31', 'Completo', 5, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(281, 37, 206, '2025-10-14', 'Completo', 4, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(282, 37, 207, '2025-10-31', 'Completo', 3, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(283, 35, 209, '2025-10-09', 'Completo', 7, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(284, 35, 210, '2025-10-10', 'Completo', 2, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(285, 33, 211, '2025-10-31', 'Completo', 1, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(286, 35, 212, '2025-10-07', 'Completo', 1, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(287, 32, 213, '2025-10-06', 'Completo', 3, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(288, 37, 215, '2025-10-06', 'Completo', 2, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(289, 36, 216, '2025-10-16', 'Completo', 4, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(290, 36, 217, '2025-10-06', 'Completo', 1, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(291, 36, 218, '2025-10-31', 'Completo', 3, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(292, 35, 219, '2025-10-23', 'Completo', 3, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(293, 38, 220, '2025-10-31', 'Completo', 1, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(294, 37, 221, '2025-10-21', 'Completo', 2, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(295, 36, 223, '2025-10-14', 'Completo', 2, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(296, 36, 224, '2025-10-20', 'Completo', 3, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(298, 35, 226, '2025-10-17', 'Completo', 1, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(299, 37, 227, '2025-10-24', 'Completo', 4, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(300, 43, 228, '2025-11-04', 'Completo', 3, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(301, 35, 229, '2025-10-22', 'Completo', 3, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(302, 33, 230, '2025-10-20', 'Completo', 1, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(303, 35, 231, '2025-10-31', 'Completo', 5, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(304, 39, 232, '2025-10-20', 'Completo', 3, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(305, 35, 233, '2025-10-20', 'Completo', 1, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(306, 36, 234, '2025-10-21', 'Completo', 1, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(307, 33, 235, '2025-10-23', 'Completo', 5, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(308, 43, 236, '2025-12-01', 'Completo', 2, '2025-11-21 21:31:03', '2025-12-01 21:03:13'),
(309, 42, 237, '2025-11-06', 'Completo', 3, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(310, 35, 238, '2025-10-27', 'Completo', 1, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(311, 42, 239, '2025-11-14', 'Completo', 2, '2025-11-21 21:31:03', '2025-11-27 20:27:48'),
(312, 42, 240, '2025-11-14', 'Completo', 1, '2025-11-21 21:31:03', '2025-11-27 20:23:56'),
(313, 41, 241, '2025-11-04', 'Completo', 5, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(314, 36, 242, '2025-10-24', 'Completo', 1, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(315, 32, 243, '2025-10-29', 'Completo', 3, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(316, 37, 244, '2025-10-27', 'Completo', 2, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(317, 37, 245, '2025-10-27', 'Completo', 1, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(318, 37, 246, '2025-10-28', 'Completo', 1, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(319, 33, 247, '2025-10-30', 'Completo', 3, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(320, 43, 248, '2025-11-05', 'Completo', 3, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(321, 32, 249, '2025-10-31', 'Completo', 3, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(322, 39, 250, '2025-10-31', 'Completo', 2, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(323, 37, 251, '2025-10-31', 'Completo', 4, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(324, 45, 252, '2025-11-02', 'Completo', 2, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(325, 40, 253, '2025-11-05', 'Completo', 3, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(326, 40, 254, '2025-11-06', 'Completo', 3, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(327, 40, 255, '2025-11-07', 'Completo', 4, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(328, 43, 256, '2025-11-30', 'Completo', 2, '2025-11-21 21:31:03', '2025-11-28 19:12:31'),
(329, 44, 257, '2025-11-10', 'Completo', 3, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(330, 45, 258, '2025-11-30', 'Completo', 4, '2025-11-21 21:31:03', '2025-11-28 19:38:35'),
(331, 45, 259, '2025-11-10', 'Completo', 3, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(332, 46, 260, '2025-11-12', 'Completo', 2, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(333, 46, 261, '2025-11-10', 'Completo', 1, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(334, 43, 262, '2025-11-11', 'Completo', 3, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(335, 43, 263, '2025-12-05', 'En proceso', 2, '2025-11-21 21:31:03', '2025-12-01 20:44:58'),
(336, 42, 264, '2025-11-21', 'Completo', 4, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(337, 44, 265, '2025-11-07', 'Completo', 2, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(338, 47, 266, '2025-11-30', 'Completo', 1, '2025-11-21 21:31:03', '2025-11-28 19:30:32'),
(339, 43, 267, '2025-11-13', 'Completo', 2, '2025-11-21 21:31:03', '2025-11-21 21:31:03'),
(340, 42, 268, '2025-11-14', 'Completo', 2, '2025-11-21 21:31:03', '2025-11-27 00:01:45'),
(341, 45, 269, '2025-11-18', 'Completo', 4, '2025-11-21 21:31:03', '2025-11-21 22:08:24'),
(342, 46, 270, '2025-11-21', 'Completo', 5, '2025-11-21 21:31:03', '2025-11-27 19:45:52'),
(343, 44, 271, '2025-11-17', 'Completo', 6, '2025-11-21 21:31:03', '2025-12-01 16:15:08'),
(344, 42, 272, '2025-11-30', 'Completo', 1, '2025-11-21 21:31:03', '2025-11-28 19:15:15'),
(345, 41, 273, '2025-11-30', 'Completo', 1, '2025-11-21 21:31:03', '2025-11-28 19:12:55'),
(398, 47, 274, '2025-11-20', 'Completo', 1, '2025-11-21 22:14:29', '2025-11-21 22:29:01'),
(399, 40, 275, '2025-11-24', 'Completo', 2, '2025-11-21 22:50:01', '2025-11-28 21:11:57'),
(400, 47, 276, '2025-11-28', 'Completo', 2, '2025-11-21 22:55:00', '2025-11-27 19:12:40'),
(401, 43, 277, '2025-11-26', 'Completo', 3, '2025-11-25 14:00:33', '2025-11-26 22:27:31'),
(402, 47, 278, '2025-11-21', 'Completo', 2, '2025-11-26 14:04:27', '2025-11-26 23:24:32'),
(403, 43, 279, '2025-11-26', 'Completo', 7, '2025-11-27 20:31:41', '2025-11-27 20:33:25'),
(404, 43, 280, '2025-11-27', 'Completo', 5, '2025-11-27 20:32:43', '2025-11-27 20:32:43'),
(405, 43, 281, '2025-11-24', 'Completo', 2, '2025-11-27 20:36:55', '2025-11-27 20:36:55'),
(406, 45, 282, '2025-11-27', 'Completo', 2, '2025-11-27 20:58:16', '2025-11-27 20:58:16'),
(407, 45, 283, '2025-11-27', 'Completo', 2, '2025-11-27 21:26:52', '2025-11-27 21:26:52'),
(408, 45, 284, '2025-11-27', 'Completo', 4, '2025-11-28 16:56:34', '2025-11-28 16:56:34'),
(409, 40, 285, '2025-11-30', 'Completo', 3, '2025-11-28 17:00:34', '2025-11-28 17:00:34'),
(410, 41, 286, '2025-11-27', 'Completo', 3, '2025-11-28 17:54:58', '2025-11-28 17:54:58'),
(411, 44, 287, '2025-11-28', 'Completo', 1, '2025-11-28 17:58:00', '2025-11-28 17:58:00'),
(412, 43, 288, '2025-11-18', 'Completo', 2, '2025-11-28 20:05:57', '2025-11-28 20:05:57'),
(413, 43, 289, '2025-11-24', 'Completo', 2, '2025-11-28 20:07:04', '2025-11-28 20:07:04'),
(414, 42, 290, '2025-11-28', 'Completo', 2, '2025-11-28 23:17:36', '2025-11-28 23:17:36'),
(415, 43, 291, '2025-11-26', 'Completo', 1, '2025-12-01 16:13:54', '2025-12-01 16:13:54'),
(416, 51, 292, '2025-12-31', 'En proceso', 2, '2025-12-01 19:27:44', '2025-12-01 20:54:23'),
(417, 50, 293, '2025-12-02', 'Completo', 1, '2025-12-01 19:37:53', '2025-12-02 19:16:18'),
(418, 50, 294, '2025-12-02', 'Completo', 4, '2025-12-01 20:45:14', '2025-12-04 00:45:03'),
(419, 50, 295, '2025-12-04', 'En proceso', 2, '2025-12-01 20:45:52', '2025-12-01 20:45:52'),
(420, 51, 297, '2025-12-03', 'Completo', 3, '2025-12-01 20:48:32', '2025-12-03 23:14:06'),
(421, 48, 298, '2025-12-04', 'En proceso', 3, '2025-12-01 20:49:34', '2025-12-01 20:49:34'),
(422, 51, 299, '2025-12-05', 'En proceso', 2, '2025-12-01 20:51:10', '2025-12-01 20:51:10'),
(423, 51, 300, '2025-12-04', 'Completo', 1, '2025-12-01 20:52:55', '2025-12-04 14:17:39'),
(424, 51, 301, '2025-12-12', 'En proceso', 3, '2025-12-01 20:55:39', '2025-12-01 20:55:39'),
(425, 49, 302, '2025-12-31', 'En proceso', 1, '2025-12-02 19:00:06', '2025-12-02 19:00:06'),
(426, 55, 303, '2025-12-31', 'En proceso', 1, '2025-12-02 19:01:21', '2025-12-02 19:01:21'),
(427, 53, 304, '2025-12-31', 'En proceso', 1, '2025-12-04 16:28:02', '2025-12-04 16:31:09'),
(428, 48, 305, '2025-12-03', 'Completo', 3, '2025-12-04 17:04:48', '2025-12-04 17:04:48'),
(429, 55, 306, '2025-12-02', 'Completo', 3, '2025-12-04 17:21:19', '2025-12-04 17:21:19'),
(430, 52, 307, '2025-12-01', 'Completo', 2, '2025-12-04 17:31:26', '2025-12-04 17:31:26'),
(431, 55, 308, '2025-12-02', 'Completo', 1, '2025-12-04 17:37:22', '2025-12-04 17:37:22');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `distribucionhora`
--

CREATE TABLE `distribucionhora` (
  `id` int(11) NOT NULL,
  `participante` int(11) NOT NULL,
  `porcentaje` int(11) NOT NULL,
  `comentario` varchar(500) NOT NULL,
  `idliquidacion` int(11) NOT NULL,
  `fecha` datetime NOT NULL,
  `horas` int(11) NOT NULL,
  `calculo` decimal(10,2) DEFAULT NULL,
  `registrado` timestamp NOT NULL DEFAULT current_timestamp(),
  `modificado` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `distribucionhora`
--

INSERT INTO `distribucionhora` (`id`, `participante`, `porcentaje`, `comentario`, `idliquidacion`, `fecha`, `horas`, `calculo`, `registrado`, `modificado`) VALUES
(4, 4, 100, '', 4, '2025-05-02 23:55:00', 2, 2.00, '2025-06-18 04:56:07', '2025-06-18 04:56:07'),
(5, 4, 100, '', 5, '2025-05-13 23:56:00', 2, 2.00, '2025-06-18 04:57:14', '2025-06-18 04:57:14'),
(6, 4, 90, '', 6, '2025-05-30 23:58:00', 1, 0.90, '2025-06-18 04:59:56', '2025-06-18 04:59:56'),
(7, 8, 10, '', 6, '2025-05-30 23:58:00', 1, 0.10, '2025-06-18 04:59:56', '2025-06-18 04:59:56'),
(8, 3, 10, '', 7, '2025-05-16 00:00:00', 1, 0.10, '2025-06-18 05:01:13', '2025-06-18 05:01:13'),
(9, 6, 10, '', 7, '2025-05-16 00:00:00', 1, 0.10, '2025-06-18 05:01:13', '2025-06-18 05:01:13'),
(10, 8, 80, '', 7, '2025-05-16 00:00:00', 1, 0.80, '2025-06-18 05:01:13', '2025-06-18 05:01:13'),
(11, 3, 50, '', 8, '2025-05-23 00:01:00', 5, 2.50, '2025-06-18 05:03:00', '2025-06-18 05:03:00'),
(12, 8, 50, '', 8, '2025-05-23 00:01:00', 5, 2.50, '2025-06-18 05:03:00', '2025-06-18 05:03:00'),
(13, 3, 80, '', 9, '2025-05-27 00:03:00', 2, 1.60, '2025-06-18 05:04:20', '2025-06-18 05:04:20'),
(14, 8, 20, '', 9, '2025-05-27 00:03:00', 2, 0.40, '2025-06-18 05:04:20', '2025-06-18 05:04:20'),
(15, 8, 100, '', 10, '2025-05-29 00:05:00', 1, 1.00, '2025-06-18 05:06:32', '2025-06-18 05:06:32'),
(16, 3, 10, '', 11, '2025-05-29 00:06:00', 1, 0.10, '2025-06-18 05:07:41', '2025-06-18 05:07:41'),
(17, 8, 90, '', 11, '2025-05-29 00:06:00', 1, 0.90, '2025-06-18 05:07:41', '2025-06-18 05:07:41'),
(18, 3, 20, '', 12, '2025-05-06 00:08:00', 1, 0.20, '2025-06-18 05:09:08', '2025-06-18 05:09:08'),
(19, 6, 20, '', 12, '2025-05-06 00:08:00', 1, 0.20, '2025-06-18 05:09:08', '2025-06-18 05:09:08'),
(20, 8, 60, '', 12, '2025-05-06 00:08:00', 1, 0.60, '2025-06-18 05:09:08', '2025-06-18 05:09:08'),
(24, 8, 100, '', 14, '2025-05-09 00:00:00', 1, 1.00, '2025-07-02 15:39:44', '2025-07-02 15:39:44'),
(25, 3, 80, '', 15, '2025-05-09 10:40:00', 3, 2.40, '2025-07-02 15:41:45', '2025-07-02 15:41:45'),
(26, 8, 20, '', 15, '2025-05-09 10:40:00', 3, 0.60, '2025-07-02 15:41:45', '2025-07-02 15:41:45'),
(27, 3, 10, '', 16, '2025-05-09 10:42:00', 2, 0.20, '2025-07-02 15:43:31', '2025-07-02 15:43:31'),
(28, 6, 80, '', 16, '2025-05-09 10:42:00', 2, 1.60, '2025-07-02 15:43:31', '2025-07-02 15:43:31'),
(29, 8, 10, '', 16, '2025-05-09 10:42:00', 2, 0.20, '2025-07-02 15:43:31', '2025-07-02 15:43:31'),
(30, 3, 50, '', 17, '2025-05-09 10:43:00', 4, 2.00, '2025-07-02 15:44:51', '2025-07-02 15:44:51'),
(31, 6, 30, '', 17, '2025-05-09 10:43:00', 4, 1.20, '2025-07-02 15:44:51', '2025-07-02 15:44:51'),
(32, 8, 20, '', 17, '2025-05-09 10:43:00', 4, 0.80, '2025-07-02 15:44:51', '2025-07-02 15:44:51'),
(33, 3, 40, '', 18, '2025-05-13 10:53:00', 9, 3.60, '2025-07-02 15:54:03', '2025-07-02 15:54:03'),
(34, 8, 60, '', 18, '2025-05-13 10:53:00', 9, 5.40, '2025-07-02 15:54:03', '2025-07-02 15:54:03'),
(35, 3, 40, '', 19, '2025-05-16 10:55:00', 2, 0.80, '2025-07-02 15:56:16', '2025-07-02 15:56:16'),
(36, 6, 60, '', 19, '2025-05-16 10:55:00', 2, 1.20, '2025-07-02 15:56:16', '2025-07-02 15:56:16'),
(37, 3, 20, '', 20, '2025-05-23 10:56:00', 4, 0.80, '2025-07-02 15:57:49', '2025-07-02 15:57:49'),
(38, 6, 60, '', 20, '2025-05-23 10:56:00', 4, 2.40, '2025-07-02 15:57:49', '2025-07-02 15:57:49'),
(39, 8, 20, '', 20, '2025-05-23 10:56:00', 4, 0.80, '2025-07-02 15:57:49', '2025-07-02 15:57:49'),
(40, 3, 40, '', 21, '2025-05-23 10:58:00', 1, 0.40, '2025-07-02 16:00:09', '2025-07-02 16:00:09'),
(41, 8, 60, '', 21, '2025-05-23 10:58:00', 1, 0.60, '2025-07-02 16:00:09', '2025-07-02 16:00:09'),
(42, 3, 30, '', 22, '2025-05-26 11:01:00', 3, 0.90, '2025-07-02 16:02:16', '2025-07-02 16:02:16'),
(43, 6, 70, '', 22, '2025-05-26 11:01:00', 3, 2.10, '2025-07-02 16:02:16', '2025-07-02 16:02:16'),
(44, 4, 90, '', 23, '2025-05-28 11:03:00', 2, 1.80, '2025-07-02 16:03:33', '2025-07-02 16:03:33'),
(45, 8, 10, '', 23, '2025-05-28 11:03:00', 2, 0.20, '2025-07-02 16:03:33', '2025-07-02 16:03:33'),
(48, 6, 90, '', 25, '2025-05-30 11:05:00', 2, 1.80, '2025-07-02 16:05:54', '2025-07-02 16:05:54'),
(49, 8, 10, '', 25, '2025-05-30 11:05:00', 2, 0.20, '2025-07-02 16:05:54', '2025-07-02 16:05:54'),
(50, 3, 50, '', 26, '2025-05-30 11:06:00', 2, 1.00, '2025-07-02 16:07:30', '2025-07-02 16:07:30'),
(51, 8, 50, '', 26, '2025-05-30 11:06:00', 2, 1.00, '2025-07-02 16:07:30', '2025-07-02 16:07:30'),
(57, 4, 95, 'Elaboración de análisis, revisión de documentos y elaboración de correo de respuesta', 31, '2025-07-02 00:00:00', 2, 1.90, '2025-07-03 00:49:53', '2025-07-03 00:49:53'),
(58, 8, 5, 'Apoyo con la estructuración de correo', 31, '2025-07-02 00:00:00', 2, 0.10, '2025-07-03 00:49:53', '2025-07-03 00:49:53'),
(59, 4, 25, 'Efectuó coordinaciones previas, tuvo participaciones en la reunión y en la toma de acuerdos', 32, '2025-07-02 17:00:00', 1, 0.25, '2025-07-03 01:21:50', '2025-07-03 01:21:50'),
(60, 8, 75, 'Dirigieron reunión y tuvieron participación activa en toda la reunión', 32, '2025-07-02 17:00:00', 1, 0.75, '2025-07-03 01:21:50', '2025-07-03 01:21:50'),
(78, 6, 70, 'Desarrollo del tema general', 35, '2025-07-02 00:00:00', 3, 2.10, '2025-07-03 18:48:27', '2025-07-03 18:48:27'),
(79, 3, 25, 'Soporte en la revisión de la matriz y elaboración de correo para trasladar los hallazgos', 35, '2025-07-02 00:00:00', 3, 0.75, '2025-07-03 18:48:27', '2025-07-03 18:48:27'),
(80, 8, 5, 'Guía para desarrollar el tema y revisión sin cambios', 35, '2025-07-02 00:00:00', 3, 0.15, '2025-07-03 18:48:27', '2025-07-03 18:48:27'),
(84, 3, 10, '', 13, '2025-05-07 00:00:00', 1, 0.10, '2025-07-04 07:55:46', '2025-07-04 07:55:46'),
(85, 6, 20, '', 13, '2025-05-07 00:00:00', 1, 0.20, '2025-07-04 07:55:46', '2025-07-04 07:55:46'),
(86, 8, 70, '', 13, '2025-05-07 00:00:00', 1, 0.70, '2025-07-04 07:55:46', '2025-07-04 07:55:46'),
(87, 6, 35, '', 39, '2025-07-04 02:30:00', 1, 0.35, '2025-07-04 21:08:56', '2025-07-04 21:08:56'),
(88, 4, 60, '', 39, '2025-07-04 02:30:00', 1, 0.60, '2025-07-04 21:08:56', '2025-07-04 21:08:56'),
(89, 3, 5, '', 39, '2025-07-04 02:30:00', 1, 0.05, '2025-07-04 21:08:56', '2025-07-04 21:08:56'),
(90, 3, 10, '', 24, '2025-07-04 10:00:00', 2, 0.20, '2025-07-04 21:11:27', '2025-07-04 21:11:27'),
(91, 6, 10, '', 24, '2025-07-04 10:00:00', 2, 0.20, '2025-07-04 21:11:27', '2025-07-04 21:11:27'),
(92, 8, 80, '', 24, '2025-07-04 10:00:00', 2, 1.60, '2025-07-04 21:11:27', '2025-07-04 21:11:27'),
(93, 3, 80, '', 30, '2025-07-02 00:00:00', 4, 3.20, '2025-07-04 21:17:01', '2025-07-04 21:17:01'),
(94, 8, 20, '', 30, '2025-07-02 00:00:00', 4, 0.80, '2025-07-04 21:17:01', '2025-07-04 21:17:01'),
(97, 3, 95, 'Revisión de normativa/ antecedentes de la NRIP / elaboración de correo', 40, '2025-07-04 16:22:00', 1, 0.95, '2025-07-04 21:31:13', '2025-07-04 21:31:13'),
(98, 8, 5, 'Recomendación PUNKU / lectura y aprobación del correo', 40, '2025-07-04 16:22:00', 1, 0.05, '2025-07-04 21:31:13', '2025-07-04 21:31:13'),
(103, 3, 50, '', 41, '2025-07-03 00:00:00', 2, 1.00, '2025-07-07 16:37:26', '2025-07-07 16:37:26'),
(104, 5, 50, '', 41, '2025-07-03 00:00:00', 2, 1.00, '2025-07-07 16:37:26', '2025-07-07 16:37:26'),
(105, 3, 100, '', 51, '2025-07-08 00:00:00', 3, 3.00, '2025-07-08 19:34:33', '2025-07-08 19:34:33'),
(106, 4, 35, '', 46, '2025-07-07 00:00:00', 4, 1.40, '2025-07-08 19:38:29', '2025-07-08 19:38:29'),
(107, 8, 65, '', 46, '2025-07-07 00:00:00', 4, 2.60, '2025-07-08 19:38:29', '2025-07-08 19:38:29'),
(110, 4, 10, '', 37, '2025-07-07 15:00:00', 1, 0.10, '2025-07-08 19:43:57', '2025-07-08 19:43:57'),
(111, 8, 90, '', 37, '2025-07-07 15:00:00', 1, 0.90, '2025-07-08 19:43:57', '2025-07-08 19:43:57'),
(112, 4, 10, '', 38, '2025-07-07 16:30:00', 1, 0.10, '2025-07-08 19:44:56', '2025-07-08 19:44:56'),
(113, 8, 90, '', 38, '2025-07-07 16:30:00', 1, 0.90, '2025-07-08 19:44:56', '2025-07-08 19:44:56'),
(114, 4, 50, '', 53, '2025-07-08 00:00:00', 2, 1.00, '2025-07-08 19:46:24', '2025-07-08 19:46:24'),
(115, 8, 50, '', 53, '2025-07-08 00:00:00', 2, 1.00, '2025-07-08 19:46:24', '2025-07-08 19:46:24'),
(116, 5, 100, '', 56, '2025-07-08 11:46:00', 3, 3.00, '2025-07-08 21:50:17', '2025-07-08 21:50:17'),
(117, 3, 20, '', 52, '2025-07-07 00:00:00', 4, 0.80, '2025-07-08 22:07:36', '2025-07-08 22:07:36'),
(118, 4, 80, '', 52, '2025-07-07 00:00:00', 4, 3.20, '2025-07-08 22:07:36', '2025-07-08 22:07:36'),
(119, 4, 50, '', 57, '2025-07-08 18:00:00', 1, 0.50, '2025-07-08 23:46:24', '2025-07-08 23:46:24'),
(120, 3, 50, '', 57, '2025-07-08 18:00:00', 1, 0.50, '2025-07-08 23:46:24', '2025-07-08 23:46:24'),
(121, 8, 5, '', 49, '2025-07-09 12:46:00', 2, 0.10, '2025-07-09 21:56:01', '2025-07-09 21:56:01'),
(122, 4, 95, '', 49, '2025-07-09 12:46:00', 2, 1.90, '2025-07-09 21:56:01', '2025-07-09 21:56:01'),
(123, 8, 100, '', 54, '2025-07-09 19:11:00', 3, 3.00, '2025-07-10 00:22:39', '2025-07-10 00:22:39'),
(124, 3, 80, 'Desarrollo de PPTS', 58, '2025-07-10 10:00:00', 2, 1.60, '2025-07-10 17:29:16', '2025-07-10 17:29:16'),
(125, 8, 20, 'Inclusión y análisis de escenarios de SMS A2P / Adecuación de títulos de la PPT', 58, '2025-07-10 10:00:00', 2, 0.40, '2025-07-10 17:29:16', '2025-07-10 17:29:16'),
(126, 3, 40, 'Presentación y detalle de escenarios', 59, '2025-07-10 10:00:00', 2, 0.80, '2025-07-10 17:50:30', '2025-07-10 17:50:30'),
(127, 8, 50, 'Presentación y detalle de escenarios', 59, '2025-07-10 10:00:00', 2, 1.00, '2025-07-10 17:50:30', '2025-07-10 17:50:30'),
(128, 6, 10, 'Acta', 59, '2025-07-10 10:00:00', 2, 0.20, '2025-07-10 17:50:30', '2025-07-10 17:50:30'),
(152, 3, 15, '', 64, '2025-07-10 15:47:00', 2, 0.30, '2025-07-10 23:15:02', '2025-07-10 23:15:02'),
(153, 4, 85, '', 64, '2025-07-10 15:47:00', 2, 1.70, '2025-07-10 23:15:02', '2025-07-10 23:15:02'),
(154, 3, 20, 'Revisión de normativa y mandato', 62, '2025-07-11 09:07:00', 1, 0.20, '2025-07-11 14:07:42', '2025-07-11 14:07:42'),
(155, 8, 80, 'Elaboración y revisión del correo', 62, '2025-07-11 09:07:00', 1, 0.80, '2025-07-11 14:07:42', '2025-07-11 14:07:42'),
(163, 6, 80, '', 66, '2025-07-11 03:00:00', 3, 2.40, '2025-07-11 22:59:16', '2025-07-11 22:59:16'),
(164, 8, 20, 'Revisión del escrito y orientación.', 66, '2025-07-11 03:00:00', 3, 0.60, '2025-07-11 22:59:16', '2025-07-11 22:59:16'),
(167, 3, 70, '', 65, '2025-07-11 19:45:00', 3, 2.10, '2025-07-12 00:46:04', '2025-07-12 00:46:04'),
(168, 8, 30, '', 65, '2025-07-11 19:45:00', 3, 0.90, '2025-07-12 00:46:04', '2025-07-12 00:46:04'),
(181, 8, 10, '', 48, '2025-07-16 00:00:00', 3, 0.30, '2025-07-17 00:05:21', '2025-07-17 00:05:21'),
(182, 4, 90, '', 48, '2025-07-16 00:00:00', 3, 2.70, '2025-07-17 00:05:21', '2025-07-17 00:05:21'),
(192, 4, 15, '', 72, '2025-07-18 11:30:00', 1, 0.15, '2025-07-19 06:46:21', '2025-07-19 06:46:21'),
(193, 8, 35, '', 72, '2025-07-18 11:30:00', 1, 0.35, '2025-07-19 06:46:21', '2025-07-19 06:46:21'),
(194, 3, 50, '', 72, '2025-07-18 11:30:00', 1, 0.50, '2025-07-19 06:46:21', '2025-07-19 06:46:21'),
(195, 8, 95, '', 82, '2025-07-18 10:00:00', 1, 0.95, '2025-07-21 14:00:25', '2025-07-21 14:00:25'),
(196, 3, 5, '', 82, '2025-07-18 10:00:00', 1, 0.05, '2025-07-21 14:00:25', '2025-07-21 14:00:25'),
(197, 4, 10, '', 85, '2025-07-18 12:00:00', 2, 0.20, '2025-07-21 15:23:40', '2025-07-21 15:23:40'),
(198, 8, 10, '', 85, '2025-07-18 12:00:00', 2, 0.20, '2025-07-21 15:23:40', '2025-07-21 15:23:40'),
(199, 3, 80, '', 85, '2025-07-18 12:00:00', 2, 1.60, '2025-07-21 15:23:40', '2025-07-21 15:23:40'),
(200, 3, 50, '', 83, '2025-07-18 05:30:00', 4, 2.00, '2025-07-21 15:41:29', '2025-07-21 15:41:29'),
(201, 4, 50, '', 83, '2025-07-18 05:30:00', 4, 2.00, '2025-07-21 15:41:29', '2025-07-21 15:41:29'),
(206, 8, 10, '', 68, '2025-07-15 00:00:00', 4, 0.40, '2025-07-21 22:24:14', '2025-07-21 22:24:14'),
(207, 4, 80, '', 68, '2025-07-15 00:00:00', 4, 3.20, '2025-07-21 22:24:14', '2025-07-21 22:24:14'),
(208, 5, 10, '', 68, '2025-07-15 00:00:00', 4, 0.40, '2025-07-21 22:24:14', '2025-07-21 22:24:14'),
(211, 6, 60, '', 84, '2025-07-21 00:00:00', 1, 0.60, '2025-07-22 15:39:14', '2025-07-22 15:39:14'),
(212, 8, 40, '', 84, '2025-07-21 00:00:00', 1, 0.40, '2025-07-22 15:39:14', '2025-07-22 15:39:14'),
(213, 4, 50, '', 90, '2025-07-24 11:30:00', 1, 0.50, '2025-07-24 16:57:02', '2025-07-24 16:57:02'),
(214, 3, 50, '', 90, '2025-07-24 11:30:00', 1, 0.50, '2025-07-24 16:57:02', '2025-07-24 16:57:02'),
(215, 8, 50, '', 74, '2025-07-24 00:00:00', 4, 2.00, '2025-07-24 18:57:47', '2025-07-24 18:57:47'),
(216, 4, 50, '', 74, '2025-07-24 00:00:00', 4, 2.00, '2025-07-24 18:57:47', '2025-07-24 18:57:47'),
(217, 3, 10, '', 88, '2025-07-24 00:00:00', 2, 0.20, '2025-07-24 18:59:26', '2025-07-24 18:59:26'),
(218, 4, 90, '', 88, '2025-07-24 00:00:00', 2, 1.80, '2025-07-24 18:59:26', '2025-07-24 18:59:26'),
(221, 5, 20, '', 47, '2025-07-24 00:00:00', 2, 0.40, '2025-07-24 19:01:36', '2025-07-24 19:01:36'),
(222, 4, 80, '', 47, '2025-07-24 00:00:00', 2, 1.60, '2025-07-24 19:01:36', '2025-07-24 19:01:36'),
(227, 3, 60, '', 78, '2025-07-21 00:00:00', 4, 2.40, '2025-07-25 19:19:16', '2025-07-25 19:19:16'),
(228, 8, 40, '', 78, '2025-07-21 00:00:00', 4, 1.60, '2025-07-25 19:19:16', '2025-07-25 19:19:16'),
(229, 4, 80, '', 79, '2025-07-22 00:00:00', 4, 3.20, '2025-07-25 19:22:20', '2025-07-25 19:22:20'),
(230, 3, 10, '', 79, '2025-07-22 00:00:00', 4, 0.40, '2025-07-25 19:22:20', '2025-07-25 19:22:20'),
(231, 8, 10, '', 79, '2025-07-22 00:00:00', 4, 0.40, '2025-07-25 19:22:20', '2025-07-25 19:22:20'),
(232, 3, 100, '', 91, '2025-07-22 12:00:00', 3, 3.00, '2025-07-25 19:25:35', '2025-07-25 19:25:35'),
(236, 3, 70, '', 63, '2025-07-25 12:00:00', 2, 1.40, '2025-07-25 19:33:36', '2025-07-25 19:33:36'),
(237, 8, 30, '', 63, '2025-07-25 12:00:00', 2, 0.60, '2025-07-25 19:33:36', '2025-07-25 19:33:36'),
(240, 6, 95, '', 67, '2025-07-18 00:00:00', 4, 3.80, '2025-07-25 21:51:53', '2025-07-25 21:51:53'),
(241, 8, 5, 'Guía para abordar el tema.', 67, '2025-07-18 00:00:00', 4, 0.20, '2025-07-25 21:51:53', '2025-07-25 21:51:53'),
(242, 6, 80, '', 36, '2025-07-03 00:00:00', 4, 3.20, '2025-07-25 21:52:41', '2025-07-25 21:52:41'),
(243, 8, 20, '', 36, '2025-07-03 00:00:00', 4, 0.80, '2025-07-25 21:52:41', '2025-07-25 21:52:41'),
(244, 6, 30, '', 33, '2025-07-02 00:00:00', 1, 0.30, '2025-07-25 21:53:44', '2025-07-25 21:53:44'),
(245, 4, 50, '', 33, '2025-07-02 00:00:00', 1, 0.50, '2025-07-25 21:53:44', '2025-07-25 21:53:44'),
(246, 3, 20, '', 33, '2025-07-02 00:00:00', 1, 0.20, '2025-07-25 21:53:44', '2025-07-25 21:53:44'),
(247, 6, 90, '', 60, '2025-07-09 00:00:00', 1, 0.90, '2025-07-25 21:55:26', '2025-07-25 21:55:26'),
(248, 8, 10, '', 60, '2025-07-09 00:00:00', 1, 0.10, '2025-07-25 21:55:26', '2025-07-25 21:55:26'),
(249, 8, 75, '', 61, '2025-07-09 00:00:00', 1, 0.75, '2025-07-25 21:56:10', '2025-07-25 21:56:10'),
(250, 6, 20, '', 61, '2025-07-09 00:00:00', 1, 0.20, '2025-07-25 21:56:10', '2025-07-25 21:56:10'),
(251, 3, 5, '', 61, '2025-07-09 00:00:00', 1, 0.05, '2025-07-25 21:56:10', '2025-07-25 21:56:10'),
(252, 3, 50, '', 75, '2025-07-25 00:00:00', 4, 2.00, '2025-07-25 23:43:23', '2025-07-25 23:43:23'),
(253, 6, 20, '', 75, '2025-07-25 00:00:00', 4, 0.80, '2025-07-25 23:43:23', '2025-07-25 23:43:23'),
(254, 8, 30, '', 75, '2025-07-25 00:00:00', 4, 1.20, '2025-07-25 23:43:23', '2025-07-25 23:43:23'),
(257, 8, 10, '', 73, '2025-07-24 00:00:00', 2, 0.20, '2025-07-30 17:27:27', '2025-07-30 17:27:27'),
(258, 4, 90, '', 73, '2025-07-24 00:00:00', 2, 1.80, '2025-07-30 17:27:27', '2025-07-30 17:27:27'),
(259, 5, 30, '', 71, '2025-07-21 00:00:00', 3, 0.90, '2025-07-30 19:06:17', '2025-07-30 19:06:17'),
(260, 8, 20, '', 71, '2025-07-21 00:00:00', 3, 0.60, '2025-07-30 19:06:17', '2025-07-30 19:06:17'),
(261, 4, 50, '', 71, '2025-07-21 00:00:00', 3, 1.50, '2025-07-30 19:06:17', '2025-07-30 19:06:17'),
(262, 6, 100, '', 92, '2025-07-31 11:00:00', 1, 1.00, '2025-07-31 15:11:37', '2025-07-31 15:11:37'),
(265, 8, 30, '', 95, '2025-07-31 17:30:00', 2, 0.60, '2025-07-31 15:17:26', '2025-07-31 15:17:26'),
(266, 4, 70, '', 95, '2025-07-31 17:30:00', 2, 1.40, '2025-07-31 15:17:26', '2025-07-31 15:17:26'),
(267, 6, 70, '', 44, '2025-07-08 00:00:00', 4, 2.80, '2025-07-31 15:20:44', '2025-07-31 15:20:44'),
(268, 8, 30, '', 44, '2025-07-08 00:00:00', 4, 1.20, '2025-07-31 15:20:44', '2025-07-31 15:20:44'),
(269, 5, 25, '', 70, '2025-07-31 00:00:00', 2, 0.50, '2025-07-31 20:46:08', '2025-07-31 20:46:08'),
(270, 3, 25, '', 70, '2025-07-31 00:00:00', 2, 0.50, '2025-07-31 20:46:08', '2025-07-31 20:46:08'),
(271, 8, 50, '', 70, '2025-07-31 00:00:00', 2, 1.00, '2025-07-31 20:46:08', '2025-07-31 20:46:08'),
(272, 3, 15, '', 55, '2025-07-31 00:00:00', 1, 0.15, '2025-07-31 20:51:53', '2025-07-31 20:51:53'),
(273, 4, 85, '', 55, '2025-07-31 00:00:00', 1, 0.85, '2025-07-31 20:51:53', '2025-07-31 20:51:53'),
(274, 3, 90, '', 80, '2025-07-25 00:00:00', 2, 1.80, '2025-07-31 21:01:08', '2025-07-31 21:01:08'),
(275, 8, 10, '', 80, '2025-07-25 00:00:00', 2, 0.20, '2025-07-31 21:01:08', '2025-07-31 21:01:08'),
(276, 6, 45, '', 89, '2025-07-30 00:00:00', 3, 1.35, '2025-07-31 21:04:39', '2025-07-31 21:04:39'),
(277, 5, 45, '', 89, '2025-07-30 00:00:00', 3, 1.35, '2025-07-31 21:04:39', '2025-07-31 21:04:39'),
(278, 4, 10, '', 89, '2025-07-30 00:00:00', 3, 0.30, '2025-07-31 21:04:39', '2025-07-31 21:04:39'),
(283, 8, 35, '', 42, '2025-07-31 00:00:00', 3, 1.05, '2025-07-31 21:22:47', '2025-07-31 21:22:47'),
(284, 4, 24, '', 42, '2025-07-31 00:00:00', 3, 0.72, '2025-07-31 21:22:47', '2025-07-31 21:22:47'),
(285, 3, 29, '', 42, '2025-07-31 00:00:00', 3, 0.87, '2025-07-31 21:22:47', '2025-07-31 21:22:47'),
(286, 6, 12, '', 42, '2025-07-31 00:00:00', 3, 0.36, '2025-07-31 21:22:47', '2025-07-31 21:22:47'),
(293, 8, 95, '', 87, '2025-07-22 00:00:00', 1, 0.95, '2025-07-31 21:55:15', '2025-07-31 21:55:15'),
(294, 6, 5, '', 87, '2025-07-22 00:00:00', 1, 0.05, '2025-07-31 21:55:15', '2025-07-31 21:55:15'),
(295, 6, 100, '', 96, '2025-07-31 01:00:00', 2, 2.00, '2025-07-31 22:29:39', '2025-07-31 22:29:39'),
(301, 6, 50, '', 45, '2025-07-17 00:00:00', 1, 0.50, '2025-07-31 23:21:07', '2025-07-31 23:21:07'),
(302, 4, 30, '', 45, '2025-07-17 00:00:00', 1, 0.30, '2025-07-31 23:21:07', '2025-07-31 23:21:07'),
(303, 3, 20, '', 45, '2025-07-17 00:00:00', 1, 0.20, '2025-07-31 23:21:07', '2025-07-31 23:21:07'),
(304, 3, 100, '', 99, '2025-08-01 12:00:00', 3, 3.00, '2025-08-01 17:09:00', '2025-08-01 17:09:00'),
(305, 5, 100, '', 43, '2025-07-08 00:00:00', 3, 3.00, '2025-08-01 17:34:07', '2025-08-01 17:34:07'),
(306, 6, 50, '', 98, '2025-07-30 00:00:00', 1, 0.50, '2025-08-01 17:45:51', '2025-08-01 17:45:51'),
(307, 8, 50, '', 98, '2025-07-30 00:00:00', 1, 0.50, '2025-08-01 17:45:51', '2025-08-01 17:45:51'),
(308, 4, 50, '', 97, '2025-07-31 00:00:00', 1, 0.50, '2025-08-01 17:49:02', '2025-08-01 17:49:02'),
(309, 8, 50, '', 97, '2025-07-31 00:00:00', 1, 0.50, '2025-08-01 17:49:02', '2025-08-01 17:49:02'),
(310, 6, 70, '', 93, '2025-07-31 00:00:00', 3, 2.10, '2025-08-01 18:36:17', '2025-08-01 18:36:17'),
(311, 8, 30, '', 93, '2025-07-31 00:00:00', 3, 0.90, '2025-08-01 18:36:17', '2025-08-01 18:36:17'),
(312, 3, 80, '', 100, '2025-07-31 17:30:00', 1, 0.80, '2025-08-01 18:40:51', '2025-08-01 18:40:51'),
(313, 8, 20, '', 100, '2025-07-31 17:30:00', 1, 0.20, '2025-08-01 18:40:51', '2025-08-01 18:40:51'),
(314, 3, 90, '', 77, '2025-07-21 00:00:00', 3, 2.70, '2025-08-01 18:52:25', '2025-08-01 18:52:25'),
(315, 8, 10, '', 77, '2025-07-21 00:00:00', 3, 0.30, '2025-08-01 18:52:25', '2025-08-01 18:52:25'),
(316, 3, 80, '', 104, '2025-08-05 16:40:00', 4, 3.20, '2025-08-05 21:40:56', '2025-08-05 21:40:56'),
(317, 8, 20, '', 104, '2025-08-05 16:40:00', 4, 0.80, '2025-08-05 21:40:56', '2025-08-05 21:40:56'),
(318, 8, 5, '', 69, '2025-08-05 00:00:00', 3, 0.15, '2025-08-08 20:33:30', '2025-08-08 20:33:30'),
(319, 6, 15, '', 69, '2025-08-05 00:00:00', 3, 0.45, '2025-08-08 20:33:30', '2025-08-08 20:33:30'),
(320, 3, 35, '', 69, '2025-08-05 00:00:00', 3, 1.05, '2025-08-08 20:33:30', '2025-08-08 20:33:30'),
(321, 4, 45, '', 69, '2025-08-05 00:00:00', 3, 1.35, '2025-08-08 20:33:30', '2025-08-08 20:33:30'),
(326, 3, 50, '', 106, '2025-08-07 15:53:00', 1, 0.50, '2025-08-08 21:23:16', '2025-08-08 21:23:16'),
(327, 8, 50, '', 106, '2025-08-07 15:53:00', 1, 0.50, '2025-08-08 21:23:16', '2025-08-08 21:23:16'),
(328, 6, 100, '', 107, '2025-08-07 08:00:00', 4, 4.00, '2025-08-08 21:25:30', '2025-08-08 21:25:30'),
(329, 3, 50, '', 103, '2025-08-07 00:00:00', 3, 1.50, '2025-08-08 21:26:10', '2025-08-08 21:26:10'),
(330, 8, 30, '', 103, '2025-08-07 00:00:00', 3, 0.90, '2025-08-08 21:26:10', '2025-08-08 21:26:10'),
(331, 6, 20, '', 103, '2025-08-07 00:00:00', 3, 0.60, '2025-08-08 21:26:10', '2025-08-08 21:26:10'),
(333, 3, 100, '', 94, '2025-08-08 17:30:00', 4, 4.00, '2025-08-08 21:30:58', '2025-08-08 21:30:58'),
(338, 4, 100, '', 109, '2025-08-07 16:42:00', 1, 1.00, '2025-08-08 21:43:26', '2025-08-08 21:43:26'),
(339, 6, 40, '', 105, '2025-08-04 00:00:00', 4, 1.60, '2025-08-08 22:01:13', '2025-08-08 22:01:13'),
(340, 3, 40, '', 105, '2025-08-04 00:00:00', 4, 1.60, '2025-08-08 22:01:13', '2025-08-08 22:01:13'),
(341, 4, 15, '', 105, '2025-08-04 00:00:00', 4, 0.60, '2025-08-08 22:01:13', '2025-08-08 22:01:13'),
(342, 8, 5, '', 105, '2025-08-04 00:00:00', 4, 0.20, '2025-08-08 22:01:13', '2025-08-08 22:01:13'),
(343, 3, 88, '', 108, '2025-08-08 00:00:00', 5, 4.40, '2025-08-11 17:10:52', '2025-08-11 17:10:52'),
(344, 6, 12, '', 108, '2025-08-08 00:00:00', 5, 0.60, '2025-08-11 17:10:52', '2025-08-11 17:10:52'),
(345, 6, 100, '', 110, '2025-08-11 04:00:00', 1, 1.00, '2025-08-11 21:45:49', '2025-08-11 21:45:49'),
(346, 6, 20, '', 111, '2025-08-12 15:00:00', 3, 0.60, '2025-08-12 21:33:54', '2025-08-12 21:33:54'),
(347, 3, 80, '', 111, '2025-08-12 15:00:00', 3, 2.40, '2025-08-12 21:33:54', '2025-08-12 21:33:54'),
(349, 3, 60, '', 114, '2025-08-13 11:00:00', 1, 0.60, '2025-08-13 16:54:27', '2025-08-13 16:54:27'),
(350, 8, 40, '', 114, '2025-08-13 11:00:00', 1, 0.40, '2025-08-13 16:54:27', '2025-08-13 16:54:27'),
(351, 6, 100, '', 115, '2025-08-14 11:00:00', 1, 1.00, '2025-08-14 17:30:50', '2025-08-14 17:30:50'),
(354, 6, 100, '', 113, '2025-08-12 00:00:00', 2, 2.00, '2025-08-15 21:27:21', '2025-08-15 21:27:21'),
(362, 3, 20, '', 118, '2025-08-15 00:00:00', 1, 0.20, '2025-08-16 00:07:21', '2025-08-16 00:07:21'),
(363, 8, 70, '', 118, '2025-08-15 00:00:00', 1, 0.70, '2025-08-16 00:07:21', '2025-08-16 00:07:21'),
(364, 6, 10, '', 118, '2025-08-15 00:00:00', 1, 0.10, '2025-08-16 00:07:21', '2025-08-16 00:07:21'),
(369, 6, 40, '', 116, '2025-08-15 00:00:00', 1, 0.40, '2025-08-16 06:31:12', '2025-08-16 06:31:12'),
(370, 3, 60, '', 116, '2025-08-15 00:00:00', 1, 0.60, '2025-08-16 06:31:12', '2025-08-16 06:31:12'),
(373, 3, 10, '', 122, '2025-08-18 08:00:00', 4, 0.40, '2025-08-19 20:12:00', '2025-08-19 20:12:00'),
(374, 4, 80, '', 122, '2025-08-18 08:00:00', 4, 3.20, '2025-08-19 20:12:00', '2025-08-19 20:12:00'),
(375, 8, 10, '', 122, '2025-08-18 08:00:00', 4, 0.40, '2025-08-19 20:12:00', '2025-08-19 20:12:00'),
(388, 8, 80, '', 127, '2025-08-21 00:00:00', 1, 0.80, '2025-08-22 14:05:08', '2025-08-22 14:05:08'),
(389, 3, 10, '', 127, '2025-08-21 00:00:00', 1, 0.10, '2025-08-22 14:05:08', '2025-08-22 14:05:08'),
(390, 6, 10, '', 127, '2025-08-21 00:00:00', 1, 0.10, '2025-08-22 14:05:08', '2025-08-22 14:05:08'),
(391, 8, 40, '', 123, '2025-08-21 00:00:00', 2, 0.80, '2025-08-22 14:13:22', '2025-08-22 14:13:22'),
(392, 3, 30, '', 123, '2025-08-21 00:00:00', 2, 0.60, '2025-08-22 14:13:22', '2025-08-22 14:13:22'),
(393, 6, 30, '', 123, '2025-08-21 00:00:00', 2, 0.60, '2025-08-22 14:13:22', '2025-08-22 14:13:22'),
(394, 3, 80, '', 117, '2025-08-15 18:53:00', 2, 1.60, '2025-08-25 14:54:39', '2025-08-25 14:54:39'),
(395, 9, 20, '', 117, '2025-08-15 18:53:00', 2, 0.40, '2025-08-25 14:54:39', '2025-08-25 14:54:39'),
(396, 3, 80, '', 137, '2025-08-15 18:53:00', 2, 1.60, '2025-08-25 14:58:34', '2025-08-25 14:58:34'),
(397, 9, 20, '', 137, '2025-08-15 18:53:00', 2, 0.40, '2025-08-25 14:58:34', '2025-08-25 14:58:34'),
(398, 6, 60, '', 138, '2025-08-25 00:00:00', 1, 0.60, '2025-08-26 20:55:43', '2025-08-26 20:55:43'),
(399, 3, 30, '', 138, '2025-08-25 00:00:00', 1, 0.30, '2025-08-26 20:55:43', '2025-08-26 20:55:43'),
(400, 9, 10, '', 138, '2025-08-25 00:00:00', 1, 0.10, '2025-08-26 20:55:43', '2025-08-26 20:55:43'),
(401, 3, 80, '', 102, '2025-08-27 00:00:00', 4, 3.20, '2025-08-26 20:58:48', '2025-08-26 20:58:48'),
(402, 9, 20, '', 102, '2025-08-27 00:00:00', 4, 0.80, '2025-08-26 20:58:48', '2025-08-26 20:58:48'),
(405, 3, 70, '', 120, '2025-08-26 00:00:00', 3, 2.10, '2025-08-28 15:18:41', '2025-08-28 15:18:41'),
(406, 9, 30, '', 120, '2025-08-26 00:00:00', 3, 0.90, '2025-08-28 15:18:41', '2025-08-28 15:18:41'),
(409, 4, 100, '', 140, '2025-08-27 00:00:00', 3, 3.00, '2025-08-29 01:07:40', '2025-08-29 01:07:40'),
(419, 4, 100, '', 125, '2025-08-20 00:00:00', 1, 1.00, '2025-08-29 01:36:53', '2025-08-29 01:36:53'),
(420, 9, 100, '', 134, '2025-08-27 00:00:00', 20, 20.00, '2025-08-29 14:06:40', '2025-08-29 14:06:40'),
(421, 9, 100, '', 133, '2025-08-29 00:00:00', 15, 15.00, '2025-08-29 14:07:10', '2025-08-29 14:07:10'),
(422, 9, 80, '', 141, '2025-08-29 09:00:00', 1, 0.80, '2025-08-29 14:44:48', '2025-08-29 14:44:48'),
(423, 3, 10, '', 141, '2025-08-29 09:00:00', 1, 0.10, '2025-08-29 14:44:48', '2025-08-29 14:44:48'),
(424, 6, 10, '', 141, '2025-08-29 09:00:00', 1, 0.10, '2025-08-29 14:44:48', '2025-08-29 14:44:48'),
(425, 6, 100, '', 142, '2025-08-29 11:00:00', 1, 1.00, '2025-08-29 16:54:50', '2025-08-29 16:54:50'),
(426, 3, 50, '', 143, '2025-08-29 11:00:00', 2, 1.00, '2025-08-29 18:02:06', '2025-08-29 18:02:06'),
(427, 9, 50, '', 143, '2025-08-29 11:00:00', 2, 1.00, '2025-08-29 18:02:06', '2025-08-29 18:02:06'),
(428, 6, 100, '', 144, '2025-08-29 08:00:00', 2, 2.00, '2025-08-29 21:24:40', '2025-08-29 21:24:40'),
(429, 4, 85, '', 139, '2025-08-29 00:00:00', 4, 3.40, '2025-08-30 06:32:18', '2025-08-30 06:32:18'),
(430, 9, 15, '', 139, '2025-08-29 00:00:00', 4, 0.60, '2025-08-30 06:32:18', '2025-08-30 06:32:18'),
(433, 9, 20, '', 124, '2025-08-26 00:00:00', 5, 1.00, '2025-08-30 06:40:55', '2025-08-30 06:40:55'),
(434, 4, 80, '', 124, '2025-08-26 00:00:00', 5, 4.00, '2025-08-30 06:40:55', '2025-08-30 06:40:55'),
(436, 4, 100, '', 136, '2025-08-31 00:00:00', 3, 3.00, '2025-08-31 23:50:55', '2025-08-31 23:50:55'),
(439, 9, 30, '', 76, '2025-08-18 00:00:00', 5, 1.50, '2025-09-01 00:19:20', '2025-09-01 00:19:20'),
(440, 4, 70, '', 76, '2025-08-18 00:00:00', 5, 3.50, '2025-09-01 00:19:20', '2025-09-01 00:19:20'),
(441, 9, 26, '', 101, '2025-08-31 00:00:00', 2, 0.52, '2025-09-01 14:48:47', '2025-09-01 14:48:47'),
(442, 3, 65, '', 101, '2025-08-31 00:00:00', 2, 1.30, '2025-09-01 14:48:47', '2025-09-01 14:48:47'),
(443, 4, 9, '', 101, '2025-08-31 00:00:00', 2, 0.18, '2025-09-01 14:48:47', '2025-09-01 14:48:47'),
(444, 3, 85, '', 149, '2025-09-01 00:00:00', 2, 1.70, '2025-09-01 19:12:57', '2025-09-01 19:12:57'),
(445, 9, 15, '', 149, '2025-09-01 00:00:00', 2, 0.30, '2025-09-01 19:12:57', '2025-09-01 19:12:57'),
(446, 4, 100, '', 145, '2025-09-01 00:00:00', 2, 2.00, '2025-09-01 23:43:20', '2025-09-01 23:43:20'),
(447, 9, 40, '', 121, '2025-08-20 00:00:00', 1, 0.40, '2025-09-01 23:50:16', '2025-09-01 23:50:16'),
(448, 4, 60, '', 121, '2025-08-20 00:00:00', 1, 0.60, '2025-09-01 23:50:16', '2025-09-01 23:50:16'),
(451, 4, 20, '', 119, '2025-08-15 00:00:00', 1, 0.20, '2025-09-01 23:53:44', '2025-09-01 23:53:44'),
(452, 9, 80, '', 119, '2025-08-15 00:00:00', 1, 0.80, '2025-09-01 23:53:44', '2025-09-01 23:53:44'),
(458, 9, 90, '', 150, '2025-09-04 00:00:00', 1, 0.90, '2025-09-04 17:23:38', '2025-09-04 17:23:38'),
(459, 3, 10, '', 150, '2025-09-04 00:00:00', 1, 0.10, '2025-09-04 17:23:38', '2025-09-04 17:23:38'),
(460, 4, 100, '', 146, '2025-09-04 00:00:00', 3, 3.00, '2025-09-04 20:23:04', '2025-09-04 20:23:04'),
(461, 4, 40, '', 157, '2025-09-02 00:00:00', 1, 0.40, '2025-09-04 20:43:58', '2025-09-04 20:43:58'),
(462, 9, 60, '', 157, '2025-09-02 00:00:00', 1, 0.60, '2025-09-04 20:43:58', '2025-09-04 20:43:58'),
(463, 6, 90, '', 160, '2025-09-02 08:00:00', 3, 2.70, '2025-09-05 21:14:32', '2025-09-05 21:14:32'),
(464, 3, 10, '', 160, '2025-09-02 08:00:00', 3, 0.30, '2025-09-05 21:14:32', '2025-09-05 21:14:32'),
(465, 6, 100, '', 161, '2025-09-05 08:00:00', 3, 3.00, '2025-09-05 21:15:43', '2025-09-05 21:15:43'),
(471, 9, 60, '', 126, '2025-09-08 11:40:00', 12, 7.20, '2025-09-08 17:41:21', '2025-09-08 17:41:21'),
(472, 3, 40, '', 126, '2025-09-08 11:40:00', 12, 4.80, '2025-09-08 17:41:21', '2025-09-08 17:41:21'),
(480, 4, 75, '', 156, '2025-09-03 00:00:00', 2, 1.50, '2025-09-08 20:41:51', '2025-09-08 20:41:51'),
(481, 3, 17, '', 156, '2025-09-03 00:00:00', 2, 0.34, '2025-09-08 20:41:51', '2025-09-08 20:41:51'),
(482, 9, 8, '', 156, '2025-09-03 00:00:00', 2, 0.16, '2025-09-08 20:41:51', '2025-09-08 20:41:51'),
(483, 9, 100, '', 167, '2025-09-05 17:18:00', 2, 2.00, '2025-09-08 22:26:35', '2025-09-08 22:26:35'),
(484, 4, 90, '', 153, '2025-09-08 00:00:00', 2, 1.80, '2025-09-09 23:33:53', '2025-09-09 23:33:53'),
(485, 9, 10, '', 153, '2025-09-08 00:00:00', 2, 0.20, '2025-09-09 23:33:53', '2025-09-09 23:33:53'),
(486, 9, 80, '', 168, '2025-09-10 11:30:00', 1, 0.80, '2025-09-11 20:12:24', '2025-09-11 20:12:24'),
(487, 4, 10, '', 168, '2025-09-10 11:30:00', 1, 0.10, '2025-09-11 20:12:24', '2025-09-11 20:12:24'),
(488, 3, 10, '', 168, '2025-09-10 11:30:00', 1, 0.10, '2025-09-11 20:12:24', '2025-09-11 20:12:24'),
(489, 4, 100, '', 169, '2025-09-10 00:00:00', 1, 1.00, '2025-09-11 20:27:22', '2025-09-11 20:27:22'),
(491, 9, 100, '', 170, '2025-09-11 09:00:00', 1, 1.00, '2025-09-11 20:46:33', '2025-09-11 20:46:33'),
(492, 4, 100, '', 135, '2025-09-10 00:00:00', 2, 2.00, '2025-09-11 21:53:33', '2025-09-11 21:53:33'),
(493, 3, 80, '', 163, '2025-09-15 12:30:00', 3, 2.40, '2025-09-15 17:30:11', '2025-09-15 17:30:11'),
(494, 9, 20, '', 163, '2025-09-15 12:30:00', 3, 0.60, '2025-09-15 17:30:11', '2025-09-15 17:30:11'),
(495, 4, 30, '', 173, '2025-09-15 17:00:00', 2, 0.60, '2025-09-16 01:27:19', '2025-09-16 01:27:19'),
(496, 3, 35, '', 173, '2025-09-15 17:00:00', 2, 0.70, '2025-09-16 01:27:19', '2025-09-16 01:27:19'),
(497, 9, 35, '', 173, '2025-09-15 17:00:00', 2, 0.70, '2025-09-16 01:27:19', '2025-09-16 01:27:19'),
(498, 9, 25, '', 174, '2025-09-16 00:00:00', 2, 0.50, '2025-09-17 01:30:42', '2025-09-17 01:30:42'),
(499, 4, 75, '', 174, '2025-09-16 00:00:00', 2, 1.50, '2025-09-17 01:30:42', '2025-09-17 01:30:42'),
(500, 3, 70, '', 152, '2025-09-15 00:00:00', 3, 2.10, '2025-09-17 14:09:03', '2025-09-17 14:09:03'),
(501, 9, 30, '', 152, '2025-09-15 00:00:00', 3, 0.90, '2025-09-17 14:09:03', '2025-09-17 14:09:03'),
(502, 9, 30, '', 147, '2025-09-17 00:00:00', 7, 2.10, '2025-09-18 01:17:17', '2025-09-18 01:17:17'),
(503, 3, 35, '', 147, '2025-09-17 00:00:00', 7, 2.45, '2025-09-18 01:17:17', '2025-09-18 01:17:17'),
(504, 4, 35, '', 147, '2025-09-17 00:00:00', 7, 2.45, '2025-09-18 01:17:17', '2025-09-18 01:17:17'),
(505, 3, 70, '', 129, '2025-09-15 00:00:00', 5, 3.50, '2025-09-18 14:47:23', '2025-09-18 14:47:23'),
(506, 9, 30, '', 129, '2025-09-15 00:00:00', 5, 1.50, '2025-09-18 14:47:23', '2025-09-18 14:47:23'),
(507, 9, 10, '', 175, '2025-09-19 00:00:00', 1, 0.10, '2025-09-19 21:35:18', '2025-09-19 21:35:18'),
(508, 4, 90, '', 175, '2025-09-19 00:00:00', 1, 0.90, '2025-09-19 21:35:18', '2025-09-19 21:35:18'),
(509, 3, 30, '', 177, '2025-09-19 12:00:00', 1, 0.30, '2025-09-19 21:38:51', '2025-09-19 21:38:51'),
(510, 9, 70, '', 177, '2025-09-19 12:00:00', 1, 0.70, '2025-09-19 21:38:51', '2025-09-19 21:38:51'),
(512, 3, 100, '', 179, '2025-09-19 00:00:00', 7, 7.00, '2025-09-22 15:43:59', '2025-09-22 15:43:59'),
(513, 4, 50, '', 172, '2025-09-22 10:45:00', 1, 0.50, '2025-09-22 22:11:23', '2025-09-22 22:11:23'),
(514, 9, 50, '', 172, '2025-09-22 10:45:00', 1, 0.50, '2025-09-22 22:11:23', '2025-09-22 22:11:23'),
(517, 3, 50, '', 185, '2025-09-23 00:00:00', 1, 0.50, '2025-09-23 15:53:08', '2025-09-23 15:53:08'),
(518, 4, 50, '', 185, '2025-09-23 00:00:00', 1, 0.50, '2025-09-23 15:53:08', '2025-09-23 15:53:08'),
(519, 3, 80, '', 188, '2025-09-23 00:00:00', 1, 0.80, '2025-09-23 17:20:24', '2025-09-23 17:20:24'),
(520, 4, 20, '', 188, '2025-09-23 00:00:00', 1, 0.20, '2025-09-23 17:20:24', '2025-09-23 17:20:24'),
(523, 3, 50, '', 176, '2025-09-18 00:00:00', 1, 0.50, '2025-09-23 18:50:38', '2025-09-23 18:50:38'),
(524, 4, 50, '', 176, '2025-09-18 00:00:00', 1, 0.50, '2025-09-23 18:50:38', '2025-09-23 18:50:38'),
(525, 4, 50, '', 189, '2025-09-23 00:00:00', 1, 0.50, '2025-09-23 19:04:23', '2025-09-23 19:04:23'),
(526, 9, 50, '', 189, '2025-09-23 00:00:00', 1, 0.50, '2025-09-23 19:04:23', '2025-09-23 19:04:23'),
(527, 3, 100, '', 190, '2025-09-23 16:30:00', 1, 1.00, '2025-09-23 21:51:23', '2025-09-23 21:51:23'),
(529, 3, 90, '', 191, '2025-09-24 17:30:00', 1, 0.90, '2025-09-25 16:44:39', '2025-09-25 16:44:39'),
(530, 9, 10, '', 191, '2025-09-24 17:30:00', 1, 0.10, '2025-09-25 16:44:39', '2025-09-25 16:44:39'),
(531, 3, 80, '', 182, '2025-09-23 00:00:00', 2, 1.60, '2025-09-25 17:41:38', '2025-09-25 17:41:38'),
(532, 9, 20, '', 182, '2025-09-23 00:00:00', 2, 0.40, '2025-09-25 17:41:38', '2025-09-25 17:41:38'),
(534, 4, 100, '', 192, '2025-09-26 14:14:00', 1, 1.00, '2025-09-26 23:18:46', '2025-09-26 23:18:46'),
(535, 9, 70, '', 186, '2025-09-26 00:00:00', 8, 5.60, '2025-09-29 13:37:27', '2025-09-29 13:37:27'),
(536, 3, 30, '', 186, '2025-09-26 00:00:00', 8, 2.40, '2025-09-29 13:37:27', '2025-09-29 13:37:27'),
(540, 4, 100, '', 178, '2025-09-26 00:00:00', 2, 2.00, '2025-09-29 18:32:54', '2025-09-29 18:32:54'),
(541, 4, 100, '', 195, '2025-09-30 00:00:00', 3, 3.00, '2025-09-29 18:59:22', '2025-09-29 18:59:22'),
(542, 3, 100, '', 151, '2025-09-30 00:00:00', 3, 3.00, '2025-09-30 19:23:56', '2025-09-30 19:23:56'),
(543, 3, 100, '', 196, '2025-09-30 10:00:00', 1, 1.00, '2025-09-30 19:27:23', '2025-09-30 19:27:23'),
(544, 3, 100, '', 155, '2025-09-30 00:00:00', 1, 1.00, '2025-09-30 19:28:24', '2025-09-30 19:28:24'),
(545, 9, 50, '', 180, '2025-09-30 00:00:00', 1, 0.50, '2025-09-30 19:30:02', '2025-09-30 19:30:02'),
(546, 3, 25, '', 180, '2025-09-30 00:00:00', 1, 0.25, '2025-09-30 19:30:02', '2025-09-30 19:30:02'),
(547, 4, 25, '', 180, '2025-09-30 00:00:00', 1, 0.25, '2025-09-30 19:30:02', '2025-09-30 19:30:02'),
(550, 3, 50, '', 197, '2025-09-29 10:00:00', 1, 0.50, '2025-09-30 19:42:21', '2025-09-30 19:42:21'),
(551, 9, 50, '', 197, '2025-09-29 10:00:00', 1, 0.50, '2025-09-30 19:42:21', '2025-09-30 19:42:21'),
(552, 9, 100, '', 166, '2025-09-30 00:00:00', 2, 2.00, '2025-09-30 20:47:01', '2025-09-30 20:47:01'),
(553, 3, 5, '', 158, '2025-09-30 00:00:00', 4, 0.20, '2025-09-30 20:59:04', '2025-09-30 20:59:04'),
(554, 9, 29, '', 158, '2025-09-30 00:00:00', 4, 1.16, '2025-09-30 20:59:04', '2025-09-30 20:59:04'),
(555, 4, 66, '', 158, '2025-09-30 00:00:00', 4, 2.64, '2025-09-30 20:59:04', '2025-09-30 20:59:04'),
(559, 4, 50, '', 187, '2025-09-30 19:00:00', 6, 3.00, '2025-10-01 00:36:12', '2025-10-01 00:36:12'),
(560, 3, 30, '', 187, '2025-09-30 19:00:00', 6, 1.80, '2025-10-01 00:36:12', '2025-10-01 00:36:12'),
(561, 9, 20, '', 187, '2025-09-30 19:00:00', 6, 1.20, '2025-10-01 00:36:12', '2025-10-01 00:36:12'),
(562, 4, 100, '', 162, '2025-09-22 00:00:00', 2, 2.00, '2025-10-01 08:10:05', '2025-10-01 08:10:05'),
(563, 3, 50, '', 198, '2025-10-02 17:30:00', 1, 0.50, '2025-10-03 17:44:36', '2025-10-03 17:44:36'),
(564, 9, 50, '', 198, '2025-10-02 17:30:00', 1, 0.50, '2025-10-03 17:44:36', '2025-10-03 17:44:36'),
(565, 9, 100, '', 199, '2025-10-03 10:30:00', 1, 1.00, '2025-10-03 17:46:00', '2025-10-03 17:46:00'),
(566, 3, 60, '', 201, '2025-10-02 09:04:00', 3, 1.80, '2025-10-03 19:21:53', '2025-10-03 19:21:53'),
(567, 9, 20, '', 201, '2025-10-02 09:04:00', 3, 0.60, '2025-10-03 19:21:53', '2025-10-03 19:21:53'),
(568, 4, 20, '', 201, '2025-10-02 09:04:00', 3, 0.60, '2025-10-03 19:21:53', '2025-10-03 19:21:53'),
(569, 3, 70, '', 194, '2025-10-03 12:00:00', 3, 2.10, '2025-10-03 19:23:40', '2025-10-03 19:23:40'),
(570, 9, 30, '', 194, '2025-10-03 12:00:00', 3, 0.90, '2025-10-03 19:23:40', '2025-10-03 19:23:40'),
(571, 4, 50, '', 203, '2025-10-02 10:30:00', 1, 0.50, '2025-10-03 20:03:24', '2025-10-03 20:03:24'),
(572, 3, 50, '', 203, '2025-10-02 10:30:00', 1, 0.50, '2025-10-03 20:03:24', '2025-10-03 20:03:24'),
(573, 4, 100, '', 204, '2025-10-03 00:00:00', 1, 1.00, '2025-10-03 20:11:06', '2025-10-03 20:11:06'),
(574, 12, 100, '', 214, '2025-10-13 12:00:00', 2, 2.00, '2025-10-06 18:31:17', '2025-10-06 18:31:17'),
(577, 3, 5, '', 217, '2025-10-06 16:00:00', 1, 0.05, '2025-10-07 14:22:35', '2025-10-07 14:22:35'),
(578, 9, 95, '', 217, '2025-10-06 16:00:00', 1, 0.95, '2025-10-07 14:22:35', '2025-10-07 14:22:35'),
(579, 3, 80, '', 184, '2025-10-07 00:00:00', 2, 1.60, '2025-10-09 20:30:55', '2025-10-09 20:30:55'),
(580, 9, 20, '', 184, '2025-10-07 00:00:00', 2, 0.40, '2025-10-09 20:30:55', '2025-10-09 20:30:55'),
(581, 3, 30, '', 209, '2025-10-09 10:00:00', 7, 2.10, '2025-10-09 20:34:16', '2025-10-09 20:34:16'),
(582, 9, 70, '', 209, '2025-10-09 10:00:00', 7, 4.90, '2025-10-09 20:34:16', '2025-10-09 20:34:16'),
(583, 9, 20, '', 212, '2025-10-07 00:00:00', 1, 0.20, '2025-10-09 20:35:11', '2025-10-09 20:35:11'),
(584, 3, 80, '', 212, '2025-10-07 00:00:00', 1, 0.80, '2025-10-09 20:35:11', '2025-10-09 20:35:11'),
(587, 3, 90, '', 210, '2025-10-10 00:00:00', 2, 1.80, '2025-10-10 18:00:58', '2025-10-10 18:00:58'),
(588, 9, 10, '', 210, '2025-10-10 00:00:00', 2, 0.20, '2025-10-10 18:00:58', '2025-10-10 18:00:58'),
(589, 3, 50, '', 183, '2025-10-06 00:00:00', 2, 1.00, '2025-10-10 18:01:27', '2025-10-10 18:01:27'),
(590, 9, 50, '', 183, '2025-10-06 00:00:00', 2, 1.00, '2025-10-10 18:01:27', '2025-10-10 18:01:27'),
(591, 4, 100, '', 213, '2025-10-06 00:00:00', 3, 3.00, '2025-10-10 20:55:26', '2025-10-10 20:55:26'),
(592, 3, 60, '', 222, '2025-10-23 13:01:00', 2, 1.20, '2025-10-13 15:12:10', '2025-10-13 15:12:10'),
(593, 9, 20, '', 222, '2025-10-23 13:01:00', 2, 0.40, '2025-10-13 15:12:10', '2025-10-13 15:12:10'),
(594, 4, 20, '', 222, '2025-10-23 13:01:00', 2, 0.40, '2025-10-13 15:12:10', '2025-10-13 15:12:10'),
(595, 9, 20, '', 193, '2025-10-14 00:00:00', 3, 0.60, '2025-10-14 22:48:21', '2025-10-14 22:48:21'),
(596, 13, 20, '', 193, '2025-10-14 00:00:00', 3, 0.60, '2025-10-14 22:48:21', '2025-10-14 22:48:21'),
(597, 3, 60, '', 193, '2025-10-14 00:00:00', 3, 1.80, '2025-10-14 22:48:21', '2025-10-14 22:48:21'),
(598, 9, 50, '', 200, '2025-10-14 16:30:00', 1, 0.50, '2025-10-14 22:50:26', '2025-10-14 22:50:26'),
(599, 3, 25, '', 200, '2025-10-14 16:30:00', 1, 0.25, '2025-10-14 22:50:26', '2025-10-14 22:50:26'),
(600, 12, 25, '', 200, '2025-10-14 16:30:00', 1, 0.25, '2025-10-14 22:50:26', '2025-10-14 22:50:26'),
(603, 12, 100, '', 223, '2025-10-14 16:30:00', 2, 2.00, '2025-10-14 22:54:55', '2025-10-14 22:54:55'),
(606, 9, 100, '', 226, '2025-10-17 00:00:00', 1, 1.00, '2025-10-17 16:42:16', '2025-10-17 16:42:16'),
(610, 4, 80, '', 224, '2025-10-20 11:00:00', 3, 2.40, '2025-10-20 16:15:51', '2025-10-20 16:15:51'),
(611, 9, 20, '', 224, '2025-10-20 11:00:00', 3, 0.60, '2025-10-20 16:15:51', '2025-10-20 16:15:51'),
(612, 3, 60, '', 216, '2025-10-16 00:00:00', 4, 2.40, '2025-10-20 16:16:46', '2025-10-20 16:16:46'),
(613, 9, 40, '', 216, '2025-10-16 00:00:00', 4, 1.60, '2025-10-20 16:16:46', '2025-10-20 16:16:46'),
(614, 9, 5, 'Revisión final.', 232, '2025-10-20 13:01:00', 3, 0.15, '2025-10-20 18:12:59', '2025-10-20 18:12:59'),
(615, 3, 5, 'Revisión de ejemplos de actividades de Base Imponible', 232, '2025-10-20 13:01:00', 3, 0.15, '2025-10-20 18:12:59', '2025-10-20 18:12:59'),
(616, 4, 45, 'Elaboración de Informe', 232, '2025-10-20 13:01:00', 3, 1.35, '2025-10-20 18:12:59', '2025-10-20 18:12:59'),
(617, 12, 45, 'Elaboración de Informe', 232, '2025-10-20 13:01:00', 3, 1.35, '2025-10-20 18:12:59', '2025-10-20 18:12:59'),
(618, 3, 50, '', 233, '2025-10-20 16:00:00', 1, 0.50, '2025-10-21 15:52:10', '2025-10-21 15:52:10'),
(619, 9, 50, '', 233, '2025-10-20 16:00:00', 1, 0.50, '2025-10-21 15:52:10', '2025-10-21 15:52:10'),
(620, 3, 10, '', 234, '2025-10-21 15:30:00', 1, 0.10, '2025-10-21 21:42:16', '2025-10-21 21:42:16'),
(621, 12, 10, '', 234, '2025-10-21 15:30:00', 1, 0.10, '2025-10-21 21:42:16', '2025-10-21 21:42:16'),
(622, 4, 30, '', 234, '2025-10-21 15:30:00', 1, 0.30, '2025-10-21 21:42:16', '2025-10-21 21:42:16'),
(623, 9, 50, '', 234, '2025-10-21 15:30:00', 1, 0.50, '2025-10-21 21:42:16', '2025-10-21 21:42:16'),
(624, 13, 50, '', 221, '2025-10-21 00:00:00', 2, 1.00, '2025-10-21 23:19:14', '2025-10-21 23:19:14'),
(625, 4, 50, '', 221, '2025-10-21 00:00:00', 2, 1.00, '2025-10-21 23:19:14', '2025-10-21 23:19:14'),
(626, 3, 10, 'Apoyo en reunión.', 230, '2025-10-20 00:00:00', 1, 0.10, '2025-10-22 15:18:07', '2025-10-22 15:18:07'),
(627, 12, 20, 'Apoyo en reunión, elaboración de matriz de pendientes.', 230, '2025-10-20 00:00:00', 1, 0.20, '2025-10-22 15:18:07', '2025-10-22 15:18:07'),
(628, 9, 70, 'Dirección de reunión.', 230, '2025-10-20 00:00:00', 1, 0.70, '2025-10-22 15:18:07', '2025-10-22 15:18:07'),
(635, 3, 90, '', 148, '2025-10-22 00:00:00', 2, 1.80, '2025-10-22 20:23:01', '2025-10-22 20:23:01'),
(636, 9, 10, '', 148, '2025-10-22 00:00:00', 2, 0.20, '2025-10-22 20:23:01', '2025-10-22 20:23:01'),
(639, 3, 70, '', 229, '2025-10-22 00:00:00', 3, 2.10, '2025-10-23 16:21:27', '2025-10-23 16:21:27'),
(640, 9, 20, '', 229, '2025-10-22 00:00:00', 3, 0.60, '2025-10-23 16:21:27', '2025-10-23 16:21:27'),
(641, 13, 10, '', 229, '2025-10-22 00:00:00', 3, 0.30, '2025-10-23 16:21:27', '2025-10-23 16:21:27'),
(642, 3, 90, '', 219, '2025-10-23 12:30:00', 3, 2.70, '2025-10-24 16:55:36', '2025-10-24 16:55:36'),
(643, 9, 10, '', 219, '2025-10-23 12:30:00', 3, 0.30, '2025-10-24 16:55:36', '2025-10-24 16:55:36'),
(647, 12, 60, 'Elaboración de comentario.', 235, '2025-10-23 00:00:00', 5, 3.00, '2025-10-24 20:14:54', '2025-10-24 20:14:54'),
(648, 13, 30, 'Revisión y reformulación del comentario.', 235, '2025-10-23 00:00:00', 5, 1.50, '2025-10-24 20:14:54', '2025-10-24 20:14:54'),
(649, 9, 10, 'Revisión final.', 235, '2025-10-23 00:00:00', 5, 0.50, '2025-10-24 20:14:54', '2025-10-24 20:14:54'),
(650, 12, 60, '', 242, '2025-10-24 17:30:00', 1, 0.60, '2025-10-27 16:37:34', '2025-10-27 16:37:34'),
(651, 13, 35, '', 242, '2025-10-24 17:30:00', 1, 0.35, '2025-10-27 16:37:34', '2025-10-27 16:37:34'),
(652, 9, 5, '', 242, '2025-10-24 17:30:00', 1, 0.05, '2025-10-27 16:37:34', '2025-10-27 16:37:34'),
(653, 9, 47, '', 218, '2025-10-31 00:00:00', 3, 1.41, '2025-10-27 16:44:10', '2025-10-27 16:44:10'),
(654, 12, 25, '', 218, '2025-10-31 00:00:00', 3, 0.75, '2025-10-27 16:44:10', '2025-10-27 16:44:10'),
(655, 4, 15, '', 218, '2025-10-31 00:00:00', 3, 0.45, '2025-10-27 16:44:10', '2025-10-27 16:44:10'),
(656, 3, 13, '', 218, '2025-10-31 00:00:00', 3, 0.39, '2025-10-27 16:44:10', '2025-10-27 16:44:10'),
(657, 9, 42, '', 202, '2025-10-31 00:00:00', 2, 0.84, '2025-10-27 16:50:39', '2025-10-27 16:50:39'),
(658, 12, 29, '', 202, '2025-10-31 00:00:00', 2, 0.58, '2025-10-27 16:50:39', '2025-10-27 16:50:39'),
(659, 3, 29, '', 202, '2025-10-31 00:00:00', 2, 0.58, '2025-10-27 16:50:39', '2025-10-27 16:50:39'),
(660, 3, 100, '', 238, '2025-10-27 00:00:00', 1, 1.00, '2025-10-29 23:21:46', '2025-10-29 23:21:46'),
(662, 4, 10, '', 244, '2025-10-27 00:00:00', 2, 0.20, '2025-10-30 15:35:24', '2025-10-30 15:35:24'),
(663, 13, 40, '', 244, '2025-10-27 00:00:00', 2, 0.80, '2025-10-30 15:35:24', '2025-10-30 15:35:24'),
(664, 9, 50, '', 244, '2025-10-27 00:00:00', 2, 1.00, '2025-10-30 15:35:24', '2025-10-30 15:35:24'),
(665, 13, 50, '', 245, '2025-10-27 18:00:00', 1, 0.50, '2025-10-30 15:36:24', '2025-10-30 15:36:24'),
(666, 9, 50, '', 245, '2025-10-27 18:00:00', 1, 0.50, '2025-10-30 15:36:24', '2025-10-30 15:36:24'),
(667, 13, 50, '', 246, '2025-10-28 00:00:00', 1, 0.50, '2025-10-30 15:38:25', '2025-10-30 15:38:25'),
(668, 9, 50, '', 246, '2025-10-28 00:00:00', 1, 0.50, '2025-10-30 15:38:25', '2025-10-30 15:38:25'),
(669, 4, 50, '', 215, '2025-10-06 00:00:00', 2, 1.00, '2025-10-30 15:42:12', '2025-10-30 15:42:12'),
(670, 9, 50, '', 215, '2025-10-06 00:00:00', 2, 1.00, '2025-10-30 15:42:12', '2025-10-30 15:42:12'),
(671, 13, 10, '', 206, '2025-10-14 00:00:00', 4, 0.40, '2025-10-30 15:44:15', '2025-10-30 15:44:15'),
(672, 4, 90, '', 206, '2025-10-14 00:00:00', 4, 3.60, '2025-10-30 15:44:15', '2025-10-30 15:44:15'),
(676, 3, 100, '', 243, '2025-10-29 00:00:00', 3, 3.00, '2025-10-30 16:30:49', '2025-10-30 16:30:49'),
(677, 3, 70, '', 247, '2025-10-30 13:10:00', 3, 2.10, '2025-10-30 18:22:31', '2025-10-30 18:22:31'),
(678, 9, 30, '', 247, '2025-10-30 13:10:00', 3, 0.90, '2025-10-30 18:22:31', '2025-10-30 18:22:31'),
(679, 4, 100, '', 249, '2025-10-31 00:00:00', 3, 3.00, '2025-10-31 19:04:02', '2025-10-31 19:04:02'),
(680, 4, 70, '', 220, '2025-10-31 00:00:00', 1, 0.70, '2025-10-31 19:06:11', '2025-10-31 19:06:11'),
(681, 9, 30, '', 220, '2025-10-31 00:00:00', 1, 0.30, '2025-10-31 19:06:11', '2025-10-31 19:06:11'),
(685, 9, 75, 'Dirección', 250, '2025-10-31 10:00:00', 2, 1.50, '2025-10-31 22:09:57', '2025-10-31 22:09:57'),
(686, 4, 15, 'Comentarios trámites', 250, '2025-10-31 10:00:00', 2, 0.30, '2025-10-31 22:09:57', '2025-10-31 22:09:57'),
(687, 3, 10, 'Comentarios trámites', 250, '2025-10-31 10:00:00', 2, 0.20, '2025-10-31 22:09:57', '2025-10-31 22:09:57'),
(688, 13, 10, '', 227, '2025-10-24 00:00:00', 4, 0.40, '2025-10-31 22:57:11', '2025-10-31 22:57:11'),
(689, 9, 12, '', 227, '2025-10-24 00:00:00', 4, 0.48, '2025-10-31 22:57:11', '2025-10-31 22:57:11'),
(690, 4, 78, '', 227, '2025-10-24 00:00:00', 4, 3.12, '2025-10-31 22:57:11', '2025-10-31 22:57:11'),
(694, 9, 8, '', 171, '2025-10-15 00:00:00', 3, 0.24, '2025-10-31 23:02:39', '2025-10-31 23:02:39'),
(695, 13, 10, '', 171, '2025-10-15 00:00:00', 3, 0.30, '2025-10-31 23:02:39', '2025-10-31 23:02:39'),
(696, 4, 82, '', 171, '2025-10-15 00:00:00', 3, 2.46, '2025-10-31 23:02:39', '2025-10-31 23:02:39'),
(697, 3, 75, '', 211, '2025-10-31 00:00:00', 1, 0.75, '2025-10-31 23:03:13', '2025-10-31 23:03:13'),
(698, 9, 25, '', 211, '2025-10-31 00:00:00', 1, 0.25, '2025-10-31 23:03:13', '2025-10-31 23:03:13'),
(699, 13, 5, '', 207, '2025-10-31 00:00:00', 3, 0.15, '2025-10-31 23:06:21', '2025-10-31 23:06:21'),
(700, 9, 15, '', 207, '2025-10-31 00:00:00', 3, 0.45, '2025-10-31 23:06:21', '2025-10-31 23:06:21'),
(701, 4, 80, '', 207, '2025-10-31 00:00:00', 3, 2.40, '2025-10-31 23:06:21', '2025-10-31 23:06:21'),
(706, 12, 5, '', 205, '2025-10-31 00:00:00', 5, 0.25, '2025-10-31 23:36:31', '2025-10-31 23:36:31'),
(707, 3, 8, '', 205, '2025-10-31 00:00:00', 5, 0.40, '2025-10-31 23:36:31', '2025-10-31 23:36:31'),
(708, 9, 15, '', 205, '2025-10-31 00:00:00', 5, 0.75, '2025-10-31 23:36:31', '2025-10-31 23:36:31'),
(709, 4, 72, '', 205, '2025-10-31 00:00:00', 5, 3.60, '2025-10-31 23:36:31', '2025-10-31 23:36:31'),
(710, 12, 25, '', 251, '2025-10-31 00:00:00', 4, 1.00, '2025-11-03 14:57:31', '2025-11-03 14:57:31'),
(711, 13, 75, '', 251, '2025-10-31 00:00:00', 4, 3.00, '2025-11-03 14:57:31', '2025-11-03 14:57:31'),
(712, 13, 100, '', 252, '2025-11-02 00:00:00', 2, 2.00, '2025-11-03 15:02:29', '2025-11-03 15:02:29'),
(713, 9, 30, '', 231, '2025-10-31 00:00:00', 5, 1.50, '2025-11-03 15:43:35', '2025-11-03 15:43:35'),
(714, 13, 20, '', 231, '2025-10-31 00:00:00', 5, 1.00, '2025-11-03 15:43:35', '2025-11-03 15:43:35'),
(715, 3, 50, '', 231, '2025-10-31 00:00:00', 5, 2.50, '2025-11-03 15:43:35', '2025-11-03 15:43:35'),
(716, 3, 100, '', 253, '2025-11-05 16:00:00', 3, 3.00, '2025-11-05 21:33:26', '2025-11-05 21:33:26'),
(717, 12, 85, 'Elaboración de guía', 241, '2025-11-04 00:00:00', 5, 4.25, '2025-11-05 22:10:42', '2025-11-05 22:10:42'),
(718, 9, 15, 'Revisión.', 241, '2025-11-04 00:00:00', 5, 0.75, '2025-11-05 22:10:42', '2025-11-05 22:10:42'),
(719, 3, 15, '', 228, '2025-11-04 10:00:00', 3, 0.45, '2025-11-05 22:14:32', '2025-11-05 22:14:32'),
(720, 9, 10, '', 228, '2025-11-04 10:00:00', 3, 0.30, '2025-11-05 22:14:32', '2025-11-05 22:14:32'),
(721, 12, 75, '', 228, '2025-11-04 10:00:00', 3, 2.25, '2025-11-05 22:14:32', '2025-11-05 22:14:32'),
(724, 3, 90, '', 237, '2025-11-06 11:00:00', 3, 2.70, '2025-11-06 17:12:22', '2025-11-06 17:12:22'),
(725, 9, 10, '', 237, '2025-11-06 11:00:00', 3, 0.30, '2025-11-06 17:12:22', '2025-11-06 17:12:22'),
(726, 3, 90, '', 248, '2025-11-05 00:00:00', 3, 2.70, '2025-11-07 23:39:30', '2025-11-07 23:39:30'),
(727, 9, 10, '', 248, '2025-11-05 00:00:00', 3, 0.30, '2025-11-07 23:39:30', '2025-11-07 23:39:30'),
(728, 9, 10, '', 265, '2025-11-07 17:30:00', 2, 0.20, '2025-11-10 13:51:08', '2025-11-10 13:51:08'),
(729, 12, 60, '', 265, '2025-11-07 17:30:00', 2, 1.20, '2025-11-10 13:51:08', '2025-11-10 13:51:08'),
(730, 3, 30, '', 265, '2025-11-07 17:30:00', 2, 0.60, '2025-11-10 13:51:08', '2025-11-10 13:51:08'),
(732, 4, 100, '', 254, '2025-11-06 00:00:00', 3, 3.00, '2025-11-10 21:33:43', '2025-11-10 21:33:43'),
(733, 13, 100, '', 261, '2025-11-10 00:00:00', 1, 1.00, '2025-11-10 21:40:27', '2025-11-10 21:40:27'),
(734, 13, 60, '', 259, '2025-11-10 00:00:00', 3, 1.80, '2025-11-10 21:57:54', '2025-11-10 21:57:54'),
(735, 4, 30, '', 259, '2025-11-10 00:00:00', 3, 0.90, '2025-11-10 21:57:54', '2025-11-10 21:57:54'),
(736, 9, 10, '', 259, '2025-11-10 00:00:00', 3, 0.30, '2025-11-10 21:57:54', '2025-11-10 21:57:54'),
(737, 9, 100, '', 257, '2025-11-10 00:00:00', 3, 3.00, '2025-11-11 14:19:22', '2025-11-11 14:19:22'),
(738, 9, 20, '', 262, '2025-11-11 00:00:00', 3, 0.60, '2025-11-11 16:05:43', '2025-11-11 16:05:43'),
(739, 3, 80, '', 262, '2025-11-11 00:00:00', 3, 2.40, '2025-11-11 16:05:43', '2025-11-11 16:05:43'),
(740, 12, 10, '', 260, '2025-11-12 16:30:00', 2, 0.20, '2025-11-13 18:11:58', '2025-11-13 18:11:58'),
(741, 4, 40, '', 260, '2025-11-12 16:30:00', 2, 0.80, '2025-11-13 18:11:58', '2025-11-13 18:11:58'),
(742, 9, 50, '', 260, '2025-11-12 16:30:00', 2, 1.00, '2025-11-13 18:11:58', '2025-11-13 18:11:58'),
(743, 4, 72, '', 255, '2025-11-07 00:00:00', 4, 2.88, '2025-11-13 21:39:03', '2025-11-13 21:39:03'),
(744, 13, 20, '', 255, '2025-11-07 00:00:00', 4, 0.80, '2025-11-13 21:39:03', '2025-11-13 21:39:03'),
(745, 2, 8, '', 255, '2025-11-07 00:00:00', 4, 0.32, '2025-11-13 21:39:03', '2025-11-13 21:39:03'),
(746, 13, 100, '', 165, '2025-11-13 15:00:00', 4, 4.00, '2025-11-14 15:25:51', '2025-11-14 15:25:51'),
(747, 9, 50, '', 267, '2025-11-13 15:00:00', 2, 1.00, '2025-11-14 15:27:36', '2025-11-14 15:27:36'),
(748, 13, 50, '', 267, '2025-11-13 15:00:00', 2, 1.00, '2025-11-14 15:27:36', '2025-11-14 15:27:36'),
(752, 3, 80, '', 264, '2025-11-21 00:00:00', 4, 3.20, '2025-11-21 20:03:29', '2025-11-21 20:03:29'),
(753, 9, 20, '', 264, '2025-11-21 00:00:00', 4, 0.80, '2025-11-21 20:03:29', '2025-11-21 20:03:29'),
(754, 9, 8, '', 269, '2025-11-18 00:00:00', 4, 0.32, '2025-11-21 22:08:24', '2025-11-21 22:08:24');
INSERT INTO `distribucionhora` (`id`, `participante`, `porcentaje`, `comentario`, `idliquidacion`, `fecha`, `horas`, `calculo`, `registrado`, `modificado`) VALUES
(755, 4, 46, '', 269, '2025-11-18 00:00:00', 4, 1.84, '2025-11-21 22:08:24', '2025-11-21 22:08:24'),
(756, 13, 46, '', 269, '2025-11-18 00:00:00', 4, 1.84, '2025-11-21 22:08:24', '2025-11-21 22:08:24'),
(757, 9, 55, 'Dirección de reunión', 274, '2025-11-20 00:00:00', 1, 0.55, '2025-11-21 22:29:01', '2025-11-21 22:29:01'),
(758, 4, 35, 'Comentarios respecto al contrato SATELCEL-URBI', 274, '2025-11-20 00:00:00', 1, 0.35, '2025-11-21 22:29:01', '2025-11-21 22:29:01'),
(759, 12, 5, 'Apoyo', 274, '2025-11-20 00:00:00', 1, 0.05, '2025-11-21 22:29:01', '2025-11-21 22:29:01'),
(760, 3, 5, 'Apoyo', 274, '2025-11-20 00:00:00', 1, 0.05, '2025-11-21 22:29:01', '2025-11-21 22:29:01'),
(761, 9, 10, '', 277, '2025-11-26 00:00:00', 3, 0.30, '2025-11-26 22:27:31', '2025-11-26 22:27:31'),
(762, 3, 90, '', 277, '2025-11-26 00:00:00', 3, 2.70, '2025-11-26 22:27:31', '2025-11-26 22:27:31'),
(763, 12, 85, 'Elaboracion', 278, '2025-11-21 00:00:00', 2, 1.70, '2025-11-26 23:24:32', '2025-11-26 23:24:32'),
(764, 3, 10, 'Apoyo', 278, '2025-11-21 00:00:00', 2, 0.20, '2025-11-26 23:24:32', '2025-11-26 23:24:32'),
(765, 9, 5, 'Apoyo', 278, '2025-11-21 00:00:00', 2, 0.10, '2025-11-26 23:24:32', '2025-11-26 23:24:32'),
(766, 9, 50, '', 268, '2025-11-14 00:00:00', 2, 1.00, '2025-11-27 00:01:45', '2025-11-27 00:01:45'),
(767, 3, 25, '', 268, '2025-11-14 00:00:00', 2, 0.50, '2025-11-27 00:01:45', '2025-11-27 00:01:45'),
(768, 13, 25, '', 268, '2025-11-14 00:00:00', 2, 0.50, '2025-11-27 00:01:45', '2025-11-27 00:01:45'),
(775, 4, 95, 'Elaboracion', 276, '2025-11-28 00:00:00', 2, 1.90, '2025-11-27 19:12:40', '2025-11-27 19:12:40'),
(776, 9, 5, 'Comentarrios', 276, '2025-11-28 00:00:00', 2, 0.10, '2025-11-27 19:12:40', '2025-11-27 19:12:40'),
(777, 4, 60, 'Revisó información y redactó versión inicial de informe. Incluyó alcances del análisis con socios de la reunión de oficina del 19.11.2025.', 270, '2025-11-21 00:00:00', 5, 3.00, '2025-11-27 19:45:52', '2025-11-27 19:45:52'),
(778, 13, 35, 'Revisó informe e incluyó mejoras en en el análisis entre el 25 y 26.11.2025', 270, '2025-11-21 00:00:00', 5, 1.75, '2025-11-27 19:45:52', '2025-11-27 19:45:52'),
(779, 9, 5, 'Se envió para revisión el 21.11.2025 pero no se completó ese día. Se revisó posteriormente con Evelyn', 270, '2025-11-21 00:00:00', 5, 0.25, '2025-11-27 19:45:52', '2025-11-27 19:45:52'),
(780, 9, 10, '', 240, '2025-11-14 00:00:00', 1, 0.10, '2025-11-27 20:23:56', '2025-11-27 20:23:56'),
(781, 3, 90, '', 240, '2025-11-14 00:00:00', 1, 0.90, '2025-11-27 20:23:56', '2025-11-27 20:23:56'),
(782, 3, 90, '', 239, '2025-11-14 00:00:00', 2, 1.80, '2025-11-27 20:27:48', '2025-11-27 20:27:48'),
(783, 9, 10, '', 239, '2025-11-14 00:00:00', 2, 0.20, '2025-11-27 20:27:48', '2025-11-27 20:27:48'),
(786, 9, 67, '', 280, '2025-11-27 09:00:00', 5, 3.35, '2025-11-27 20:32:43', '2025-11-27 20:32:43'),
(787, 3, 33, '', 280, '2025-11-27 09:00:00', 5, 1.65, '2025-11-27 20:32:43', '2025-11-27 20:32:43'),
(788, 9, 50, '', 279, '2025-11-26 00:00:00', 7, 3.50, '2025-11-27 20:33:25', '2025-11-27 20:33:25'),
(789, 3, 50, '', 279, '2025-11-26 00:00:00', 7, 3.50, '2025-11-27 20:33:25', '2025-11-27 20:33:25'),
(790, 9, 60, '', 281, '2025-11-24 09:00:00', 2, 1.20, '2025-11-27 20:36:55', '2025-11-27 20:36:55'),
(791, 13, 30, '', 281, '2025-11-24 09:00:00', 2, 0.60, '2025-11-27 20:36:55', '2025-11-27 20:36:55'),
(792, 3, 10, '', 281, '2025-11-24 09:00:00', 2, 0.20, '2025-11-27 20:36:55', '2025-11-27 20:36:55'),
(793, 13, 50, '', 282, '2025-11-27 00:00:00', 2, 1.00, '2025-11-27 20:58:16', '2025-11-27 20:58:16'),
(794, 4, 45, '', 282, '2025-11-27 00:00:00', 2, 0.90, '2025-11-27 20:58:16', '2025-11-27 20:58:16'),
(795, 9, 5, '', 282, '2025-11-27 00:00:00', 2, 0.10, '2025-11-27 20:58:16', '2025-11-27 20:58:16'),
(796, 13, 100, '', 283, '2025-11-27 00:00:00', 2, 2.00, '2025-11-27 21:26:52', '2025-11-27 21:26:52'),
(797, 13, 100, '', 284, '2025-11-27 00:00:00', 4, 4.00, '2025-11-28 16:56:34', '2025-11-28 16:56:34'),
(798, 4, 100, '', 285, '2025-11-30 00:00:00', 3, 3.00, '2025-11-28 17:00:34', '2025-11-28 17:00:34'),
(799, 9, 50, '', 286, '2025-11-27 12:53:00', 3, 1.50, '2025-11-28 17:54:58', '2025-11-28 17:54:58'),
(800, 3, 50, '', 286, '2025-11-27 12:53:00', 3, 1.50, '2025-11-28 17:54:58', '2025-11-28 17:54:58'),
(801, 9, 100, '', 287, '2025-11-28 12:00:00', 1, 1.00, '2025-11-28 17:58:00', '2025-11-28 17:58:00'),
(805, 9, 40, '', 256, '2025-11-30 00:00:00', 2, 0.80, '2025-11-28 19:12:31', '2025-11-28 19:12:31'),
(806, 3, 60, '', 256, '2025-11-30 00:00:00', 2, 1.20, '2025-11-28 19:12:31', '2025-11-28 19:12:31'),
(807, 9, 100, 'Horas Audio', 273, '2025-11-30 00:00:00', 1, 1.00, '2025-11-28 19:12:55', '2025-11-28 19:12:55'),
(808, 4, 50, '', 272, '2025-11-30 00:00:00', 1, 0.50, '2025-11-28 19:15:15', '2025-11-28 19:15:15'),
(809, 3, 50, '', 272, '2025-11-30 00:00:00', 1, 0.50, '2025-11-28 19:15:15', '2025-11-28 19:15:15'),
(810, 3, 65, 'Llamada y mensajes', 266, '2025-11-30 00:00:00', 1, 0.65, '2025-11-28 19:30:32', '2025-11-28 19:30:32'),
(811, 4, 10, 'Llamada', 266, '2025-11-30 00:00:00', 1, 0.10, '2025-11-28 19:30:32', '2025-11-28 19:30:32'),
(812, 9, 25, 'Mensajes', 266, '2025-11-30 00:00:00', 1, 0.25, '2025-11-28 19:30:32', '2025-11-28 19:30:32'),
(813, 13, 28, '', 258, '2025-11-30 00:00:00', 4, 1.12, '2025-11-28 19:38:35', '2025-11-28 19:38:35'),
(814, 9, 32, '', 258, '2025-11-30 00:00:00', 4, 1.28, '2025-11-28 19:38:35', '2025-11-28 19:38:35'),
(815, 4, 40, '', 258, '2025-11-30 00:00:00', 4, 1.60, '2025-11-28 19:38:35', '2025-11-28 19:38:35'),
(816, 13, 95, '', 288, '2025-11-18 15:03:00', 2, 1.90, '2025-11-28 20:05:57', '2025-11-28 20:05:57'),
(817, 9, 5, '', 288, '2025-11-18 15:03:00', 2, 0.10, '2025-11-28 20:05:57', '2025-11-28 20:05:57'),
(818, 9, 5, '', 289, '2025-11-24 15:06:00', 2, 0.10, '2025-11-28 20:07:04', '2025-11-28 20:07:04'),
(819, 13, 95, '', 289, '2025-11-24 15:06:00', 2, 1.90, '2025-11-28 20:07:04', '2025-11-28 20:07:04'),
(820, 13, 10, 'Revisó observación y propuso texto para subsanar en base al Peruanizado.', 275, '2025-11-24 00:00:00', 2, 0.20, '2025-11-28 21:11:57', '2025-11-28 21:11:57'),
(821, 4, 90, 'Revisó observación, hizo consultas a INDECOPI, complementó el texto y elaboró cartas de respuesta hasta el 24.11. Socios brindaron su ok a texto el 27.11; ese mismo día se ingresaron las respuestas.', 275, '2025-11-24 00:00:00', 2, 1.80, '2025-11-28 21:11:57', '2025-11-28 21:11:57'),
(822, 9, 50, '', 290, '2025-11-28 18:15:00', 2, 1.00, '2025-11-28 23:17:36', '2025-11-28 23:17:36'),
(823, 3, 50, '', 290, '2025-11-28 18:15:00', 2, 1.00, '2025-11-28 23:17:36', '2025-11-28 23:17:36'),
(824, 3, 50, '', 291, '2025-11-26 11:09:00', 1, 0.50, '2025-12-01 16:13:54', '2025-12-01 16:13:54'),
(825, 9, 50, '', 291, '2025-11-26 11:09:00', 1, 0.50, '2025-12-01 16:13:54', '2025-12-01 16:13:54'),
(826, 12, 40, '', 271, '2025-11-17 00:00:00', 6, 2.40, '2025-12-01 16:15:08', '2025-12-01 16:15:08'),
(827, 3, 40, '', 271, '2025-11-17 00:00:00', 6, 2.40, '2025-12-01 16:15:08', '2025-12-01 16:15:08'),
(828, 9, 20, '', 271, '2025-11-17 00:00:00', 6, 1.20, '2025-12-01 16:15:08', '2025-12-01 16:15:08'),
(829, 9, 40, '', 236, '2025-12-01 00:00:00', 2, 0.80, '2025-12-01 21:03:13', '2025-12-01 21:03:13'),
(830, 3, 60, '', 236, '2025-12-01 00:00:00', 2, 1.20, '2025-12-01 21:03:13', '2025-12-01 21:03:13'),
(831, 9, 50, '', 293, '2025-12-02 00:00:00', 1, 0.50, '2025-12-02 19:16:18', '2025-12-02 19:16:18'),
(832, 4, 10, '', 293, '2025-12-02 00:00:00', 1, 0.10, '2025-12-02 19:16:18', '2025-12-02 19:16:18'),
(833, 3, 40, '', 293, '2025-12-02 00:00:00', 1, 0.40, '2025-12-02 19:16:18', '2025-12-02 19:16:18'),
(834, 9, 30, '', 296, '2025-12-03 00:00:00', 3, 0.90, '2025-12-03 23:05:17', '2025-12-03 23:05:17'),
(835, 13, 5, '', 296, '2025-12-03 00:00:00', 3, 0.15, '2025-12-03 23:05:17', '2025-12-03 23:05:17'),
(836, 3, 65, '', 296, '2025-12-03 00:00:00', 3, 1.95, '2025-12-03 23:05:17', '2025-12-03 23:05:17'),
(837, 3, 85, '', 297, '2025-12-03 00:00:00', 3, 2.55, '2025-12-03 23:14:06', '2025-12-03 23:14:06'),
(838, 13, 5, '', 297, '2025-12-03 00:00:00', 3, 0.15, '2025-12-03 23:14:06', '2025-12-03 23:14:06'),
(839, 9, 10, '', 297, '2025-12-03 00:00:00', 3, 0.30, '2025-12-03 23:14:06', '2025-12-03 23:14:06'),
(840, 3, 75, '', 294, '2025-12-02 00:00:00', 4, 3.00, '2025-12-04 00:45:03', '2025-12-04 00:45:03'),
(841, 9, 15, '', 294, '2025-12-02 00:00:00', 4, 0.60, '2025-12-04 00:45:03', '2025-12-04 00:45:03'),
(842, 13, 10, '', 294, '2025-12-02 00:00:00', 4, 0.40, '2025-12-04 00:45:03', '2025-12-04 00:45:03'),
(843, 3, 100, '', 300, '2025-12-04 00:00:00', 1, 1.00, '2025-12-04 14:17:39', '2025-12-04 14:17:39'),
(844, 4, 100, '', 305, '2025-12-03 00:00:00', 3, 3.00, '2025-12-04 17:04:48', '2025-12-04 17:04:48'),
(845, 4, 80, 'Elaboracion', 306, '2025-12-02 12:19:00', 3, 2.40, '2025-12-04 17:21:19', '2025-12-04 17:21:19'),
(846, 9, 20, 'Revisión', 306, '2025-12-02 12:19:00', 3, 0.60, '2025-12-04 17:21:19', '2025-12-04 17:21:19'),
(847, 12, 90, 'Elaboracion', 307, '2025-12-01 12:23:00', 2, 1.80, '2025-12-04 17:31:26', '2025-12-04 17:31:26'),
(848, 9, 10, 'Revision y comentarios', 307, '2025-12-01 12:23:00', 2, 0.20, '2025-12-04 17:31:26', '2025-12-04 17:31:26'),
(849, 9, 55, 'Dirección', 308, '2025-12-02 12:32:00', 1, 0.55, '2025-12-04 17:37:22', '2025-12-04 17:37:22'),
(850, 4, 45, 'Apoyo', 308, '2025-12-02 12:32:00', 1, 0.45, '2025-12-04 17:37:22', '2025-12-04 17:37:22');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `distribucion_planificacion`
--

CREATE TABLE `distribucion_planificacion` (
  `iddistribucionplan` int(11) NOT NULL,
  `iddetalle` int(11) NOT NULL,
  `idparticipante` int(11) NOT NULL,
  `porcentaje` int(11) NOT NULL,
  `horas_asignadas` decimal(10,2) DEFAULT NULL,
  `registrado` timestamp NOT NULL DEFAULT current_timestamp(),
  `modificado` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `distribucion_planificacion`
--

INSERT INTO `distribucion_planificacion` (`iddistribucionplan`, `iddetalle`, `idparticipante`, `porcentaje`, `horas_asignadas`, `registrado`, `modificado`) VALUES
(2278, 145, 3, 100, 4.00, '2025-08-15 18:16:16', '2025-08-15 18:16:16'),
(4079, 1, 4, 100, 2.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4080, 2, 4, 100, 2.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4081, 3, 4, 90, 0.90, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4082, 3, 8, 10, 0.10, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4083, 18, 3, 10, 0.10, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4084, 18, 6, 10, 0.10, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4085, 18, 8, 80, 0.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4086, 19, 3, 50, 2.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4087, 19, 8, 50, 2.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4088, 20, 3, 80, 1.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4089, 20, 8, 20, 0.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4090, 21, 8, 100, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4091, 22, 3, 10, 0.10, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4092, 22, 8, 90, 0.90, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4093, 4, 3, 20, 0.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4094, 4, 6, 20, 0.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4095, 4, 8, 60, 0.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4096, 13, 3, 10, 0.10, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4097, 13, 6, 20, 0.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4098, 13, 8, 70, 0.70, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4099, 14, 8, 100, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4100, 5, 3, 80, 2.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4101, 5, 8, 20, 0.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4102, 6, 3, 10, 0.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4103, 6, 6, 80, 1.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4104, 6, 8, 10, 0.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4105, 7, 3, 50, 2.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4106, 7, 6, 30, 1.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4107, 7, 8, 20, 0.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4108, 8, 3, 40, 3.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4109, 8, 8, 60, 5.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4110, 9, 3, 40, 0.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4111, 9, 6, 60, 1.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4112, 15, 3, 20, 0.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4113, 15, 6, 60, 2.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4114, 15, 8, 20, 0.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4115, 10, 3, 40, 0.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4116, 10, 8, 60, 0.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4117, 16, 3, 30, 0.90, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4118, 16, 6, 70, 2.10, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4119, 11, 4, 90, 1.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4120, 11, 8, 10, 0.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4121, 46, 3, 10, 0.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4122, 46, 6, 10, 0.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4123, 46, 8, 80, 1.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4124, 17, 6, 90, 1.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4125, 17, 8, 10, 0.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4126, 12, 3, 50, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4127, 12, 8, 50, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4128, 47, 3, 80, 3.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4129, 47, 8, 20, 0.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4130, 62, 4, 95, 1.90, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4131, 62, 8, 5, 0.10, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4132, 23, 4, 25, 0.25, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4133, 23, 8, 75, 0.75, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4134, 55, 6, 30, 0.30, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4135, 55, 4, 50, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4136, 55, 3, 20, 0.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4137, 56, 6, 70, 2.10, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4138, 56, 3, 25, 0.75, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4139, 56, 8, 5, 0.15, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4140, 42, 6, 80, 3.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4141, 42, 8, 20, 0.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4142, 24, 4, 10, 0.10, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4143, 24, 8, 90, 0.90, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4144, 39, 4, 10, 0.10, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4145, 39, 8, 90, 0.90, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4146, 57, 6, 35, 0.35, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4147, 57, 4, 60, 0.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4148, 57, 3, 5, 0.05, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4149, 48, 3, 95, 0.95, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4150, 48, 8, 5, 0.05, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4151, 63, 3, 50, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4152, 63, 5, 50, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4153, 49, 8, 35, 1.05, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4154, 49, 4, 24, 0.72, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4155, 49, 3, 29, 0.87, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4156, 49, 6, 12, 0.36, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4157, 65, 5, 100, 3.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4158, 43, 6, 70, 2.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4159, 43, 8, 30, 1.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4160, 58, 6, 50, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4161, 58, 4, 30, 0.30, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4162, 58, 3, 20, 0.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4163, 25, 4, 35, 1.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4164, 25, 8, 65, 2.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4165, 33, 5, 20, 0.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4166, 33, 4, 80, 1.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4167, 34, 8, 10, 0.30, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4168, 34, 4, 90, 2.70, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4169, 35, 8, 5, 0.10, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4170, 35, 4, 95, 1.90, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4171, 66, 3, 100, 3.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4172, 59, 3, 20, 0.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4173, 59, 4, 80, 3.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4174, 26, 4, 50, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4175, 26, 8, 50, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4176, 27, 8, 100, 3.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4177, 36, 3, 15, 0.15, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4178, 36, 4, 85, 0.85, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4179, 67, 5, 100, 3.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4180, 28, 4, 50, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4181, 28, 3, 50, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4182, 50, 3, 80, 1.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4183, 50, 8, 20, 0.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4184, 51, 3, 40, 0.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4185, 51, 8, 50, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4186, 51, 6, 10, 0.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4187, 60, 6, 90, 0.90, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4188, 60, 8, 10, 0.10, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4189, 61, 8, 75, 0.75, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4190, 61, 6, 20, 0.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4191, 61, 3, 5, 0.05, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4192, 52, 3, 20, 0.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4193, 52, 8, 80, 0.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4194, 53, 3, 70, 1.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4195, 53, 8, 30, 0.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4196, 29, 3, 15, 0.30, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4197, 29, 4, 85, 1.70, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4198, 54, 3, 70, 2.10, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4199, 54, 8, 30, 0.90, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4200, 45, 6, 80, 2.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4201, 45, 8, 20, 0.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4202, 44, 6, 95, 3.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4203, 44, 8, 5, 0.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4204, 40, 8, 10, 0.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4205, 40, 4, 80, 3.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4206, 40, 5, 10, 0.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4207, 37, 8, 5, 0.15, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4208, 37, 6, 15, 0.45, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4209, 37, 3, 35, 1.05, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4210, 37, 4, 45, 1.35, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4211, 30, 5, 25, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4212, 30, 3, 25, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4213, 30, 8, 50, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4214, 41, 5, 30, 0.90, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4215, 41, 8, 20, 0.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4216, 41, 4, 50, 1.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4217, 38, 4, 15, 0.15, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4218, 38, 8, 35, 0.35, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4219, 38, 3, 50, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4220, 31, 8, 10, 0.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4221, 31, 4, 90, 1.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4222, 32, 8, 50, 2.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4223, 32, 4, 50, 2.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4224, 64, 3, 50, 2.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4225, 64, 6, 20, 0.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4226, 64, 8, 30, 1.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4227, 128, 9, 30, 1.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4228, 128, 4, 70, 3.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4229, 139, 3, 90, 2.70, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4230, 139, 8, 10, 0.30, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4231, 129, 3, 60, 2.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4232, 129, 8, 40, 1.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4233, 130, 4, 80, 3.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4234, 130, 3, 10, 0.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4235, 130, 8, 10, 0.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4236, 131, 3, 90, 1.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4237, 131, 8, 10, 0.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4238, 133, 8, 95, 0.95, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4239, 133, 3, 5, 0.05, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4240, 134, 3, 50, 2.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4241, 134, 4, 50, 2.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4242, 135, 6, 60, 0.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4243, 135, 8, 40, 0.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4244, 136, 4, 10, 0.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4245, 136, 8, 10, 0.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4246, 136, 3, 80, 1.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4247, 138, 8, 95, 0.95, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4248, 138, 6, 5, 0.05, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4249, 140, 3, 10, 0.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4250, 140, 4, 90, 1.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4251, 141, 6, 45, 1.35, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4252, 141, 5, 45, 1.35, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4253, 141, 4, 10, 0.30, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4254, 142, 4, 50, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4255, 142, 3, 50, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4256, 143, 3, 100, 3.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4257, 144, 6, 70, 2.10, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4258, 144, 8, 30, 0.90, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4259, 146, 8, 30, 0.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4260, 146, 4, 70, 1.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4261, 147, 4, 50, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4262, 147, 8, 50, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4263, 148, 6, 50, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4264, 148, 8, 50, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4265, 150, 3, 100, 3.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4266, 149, 3, 80, 0.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4267, 149, 8, 20, 0.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4268, 155, 9, 26, 0.52, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4269, 155, 3, 65, 1.30, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4270, 155, 4, 9, 0.18, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4271, 156, 3, 80, 3.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4272, 156, 9, 20, 0.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4273, 157, 3, 50, 1.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4274, 157, 8, 30, 0.90, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4275, 157, 6, 20, 0.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4276, 158, 3, 80, 3.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4277, 158, 8, 20, 0.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4278, 161, 6, 40, 1.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4279, 161, 3, 40, 1.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4280, 161, 4, 15, 0.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4281, 161, 8, 5, 0.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4282, 163, 6, 100, 4.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4283, 159, 3, 88, 4.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4284, 159, 6, 12, 0.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4285, 151, 4, 100, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4286, 162, 6, 100, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4287, 160, 6, 20, 0.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4288, 160, 3, 80, 2.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4289, 153, 6, 100, 2.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4290, 154, 3, 60, 0.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4291, 154, 8, 40, 0.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4292, 170, 6, 100, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4293, 171, 6, 40, 0.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4294, 171, 3, 60, 0.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4295, 172, 3, 80, 1.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4296, 172, 9, 20, 0.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4297, 173, 3, 20, 0.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4298, 173, 8, 70, 0.70, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4299, 173, 6, 10, 0.10, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4300, 174, 4, 20, 0.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4301, 174, 9, 80, 0.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4302, 175, 3, 70, 2.10, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4303, 175, 9, 30, 0.90, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4304, 176, 9, 40, 0.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4305, 176, 4, 60, 0.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4306, 177, 3, 10, 0.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4307, 177, 4, 80, 3.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4308, 177, 8, 10, 0.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4309, 178, 8, 40, 0.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4310, 178, 3, 30, 0.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4311, 178, 6, 30, 0.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4312, 179, 9, 20, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4313, 179, 4, 80, 4.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4314, 180, 4, 100, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4315, 181, 9, 60, 7.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4316, 181, 3, 40, 4.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4317, 182, 8, 80, 0.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4318, 182, 3, 10, 0.10, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4319, 182, 6, 10, 0.10, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4320, 184, 3, 70, 3.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4321, 184, 9, 30, 1.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4322, 188, 9, 100, 15.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4323, 189, 9, 100, 20.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4324, 190, 4, 100, 2.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4325, 191, 4, 100, 3.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4326, 192, 3, 80, 1.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4327, 192, 9, 20, 0.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4328, 193, 6, 60, 0.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4329, 193, 3, 30, 0.30, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4330, 193, 9, 10, 0.10, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4331, 194, 4, 85, 3.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4332, 194, 9, 15, 0.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4333, 195, 4, 100, 3.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4334, 196, 9, 80, 0.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4335, 196, 3, 10, 0.10, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4336, 196, 6, 10, 0.10, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4337, 197, 6, 100, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4338, 198, 3, 50, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4339, 198, 9, 50, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4340, 199, 6, 100, 2.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4341, 201, 4, 100, 2.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4342, 202, 4, 100, 3.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4343, 203, 9, 30, 2.10, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4344, 203, 3, 35, 2.45, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4345, 203, 4, 35, 2.45, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4346, 204, 3, 90, 1.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4347, 204, 9, 10, 0.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4348, 205, 3, 85, 1.70, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4349, 205, 9, 15, 0.30, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4350, 206, 9, 90, 0.90, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4351, 206, 3, 10, 0.10, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4352, 207, 3, 100, 3.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4353, 208, 3, 70, 2.10, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4354, 208, 9, 30, 0.90, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4355, 209, 4, 90, 1.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4356, 209, 9, 10, 0.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4357, 211, 3, 100, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4358, 212, 4, 75, 1.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4359, 212, 3, 17, 0.34, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4360, 212, 9, 8, 0.16, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4361, 213, 4, 40, 0.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4362, 213, 9, 60, 0.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4363, 214, 3, 5, 0.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4364, 214, 9, 29, 1.16, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4365, 214, 4, 66, 2.64, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4366, 271, 6, 90, 2.70, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4367, 271, 3, 10, 0.30, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4368, 272, 6, 100, 3.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4369, 270, 4, 100, 2.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4370, 215, 3, 80, 2.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4371, 215, 9, 20, 0.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4372, 217, 13, 100, 4.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4373, 218, 9, 100, 2.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4374, 219, 9, 100, 2.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4375, 220, 9, 80, 0.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4376, 220, 4, 10, 0.10, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4377, 220, 3, 10, 0.10, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4378, 221, 4, 100, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4379, 222, 9, 100, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4380, 223, 9, 8, 0.24, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4381, 223, 13, 10, 0.30, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4382, 223, 4, 82, 2.46, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4383, 224, 4, 50, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4384, 224, 9, 50, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4385, 225, 4, 30, 0.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4386, 225, 3, 35, 0.70, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4387, 225, 9, 35, 0.70, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4388, 226, 9, 25, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4389, 226, 4, 75, 1.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4390, 227, 9, 10, 0.10, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4391, 227, 4, 90, 0.90, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4392, 228, 3, 50, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4393, 228, 4, 50, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4394, 229, 3, 30, 0.30, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4395, 229, 9, 70, 0.70, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4396, 230, 4, 100, 2.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4397, 231, 3, 100, 7.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4398, 232, 9, 50, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4399, 232, 3, 25, 0.25, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4400, 232, 4, 25, 0.25, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4401, 234, 3, 80, 1.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4402, 234, 9, 20, 0.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4403, 235, 3, 50, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4404, 235, 9, 50, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4405, 236, 3, 80, 1.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4406, 236, 9, 20, 0.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4407, 237, 3, 50, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4408, 237, 4, 50, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4409, 238, 9, 70, 5.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4410, 238, 3, 30, 2.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4411, 239, 4, 50, 3.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4412, 239, 3, 30, 1.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4413, 239, 9, 20, 1.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4414, 240, 3, 80, 0.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4415, 240, 4, 20, 0.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4416, 241, 4, 50, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4417, 241, 9, 50, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4418, 242, 3, 100, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4419, 243, 3, 90, 0.90, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4420, 243, 9, 10, 0.10, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4421, 264, 4, 100, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4422, 265, 9, 20, 0.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4423, 265, 13, 20, 0.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4424, 265, 3, 60, 1.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4425, 266, 3, 70, 2.10, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4426, 266, 9, 30, 0.90, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4427, 267, 4, 100, 3.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4428, 268, 3, 100, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4429, 269, 3, 50, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4430, 269, 9, 50, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4431, 273, 3, 50, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4432, 273, 9, 50, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4433, 274, 9, 100, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4434, 275, 9, 50, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4435, 275, 3, 25, 0.25, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4436, 275, 12, 25, 0.25, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4437, 276, 3, 60, 1.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4438, 276, 9, 20, 0.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4439, 276, 4, 20, 0.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4440, 277, 9, 42, 0.84, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4441, 277, 12, 29, 0.58, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4442, 277, 3, 29, 0.58, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4443, 278, 4, 50, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4444, 278, 3, 50, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4445, 279, 4, 100, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4446, 280, 12, 5, 0.25, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4447, 280, 3, 8, 0.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4448, 280, 9, 15, 0.75, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4449, 280, 4, 72, 3.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4450, 281, 13, 10, 0.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4451, 281, 4, 90, 3.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4452, 282, 13, 5, 0.15, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4453, 282, 9, 15, 0.45, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4454, 282, 4, 80, 2.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4455, 283, 3, 30, 2.10, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4456, 283, 9, 70, 4.90, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4457, 284, 3, 90, 1.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4458, 284, 9, 10, 0.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4459, 285, 3, 75, 0.75, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4460, 285, 9, 25, 0.25, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4461, 286, 9, 20, 0.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4462, 286, 3, 80, 0.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4463, 287, 4, 100, 3.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4464, 288, 4, 50, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4465, 288, 9, 50, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4466, 289, 3, 60, 2.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4467, 289, 9, 40, 1.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4468, 290, 3, 5, 0.05, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4469, 290, 9, 95, 0.95, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4470, 291, 9, 47, 1.41, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4471, 291, 12, 25, 0.75, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4472, 291, 4, 15, 0.45, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4473, 291, 3, 13, 0.39, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4474, 292, 3, 90, 2.70, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4475, 292, 9, 10, 0.30, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4476, 293, 4, 70, 0.70, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4477, 293, 9, 30, 0.30, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4478, 294, 13, 50, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4479, 294, 4, 50, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4480, 295, 12, 100, 2.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4481, 296, 4, 80, 2.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4482, 296, 9, 20, 0.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4483, 298, 9, 100, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4484, 299, 13, 10, 0.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4485, 299, 9, 12, 0.48, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4486, 299, 4, 78, 3.12, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4487, 300, 3, 15, 0.45, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4488, 300, 9, 10, 0.30, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4489, 300, 12, 75, 2.25, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4490, 301, 3, 70, 2.10, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4491, 301, 9, 20, 0.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4492, 301, 13, 10, 0.30, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4493, 302, 3, 10, 0.10, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4494, 302, 12, 20, 0.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4495, 302, 9, 70, 0.70, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4496, 303, 9, 30, 1.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4497, 303, 13, 20, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4498, 303, 3, 50, 2.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4499, 304, 9, 5, 0.15, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4500, 304, 3, 5, 0.15, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4501, 304, 4, 45, 1.35, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4502, 304, 12, 45, 1.35, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4503, 305, 3, 50, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4504, 305, 9, 50, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4505, 306, 3, 10, 0.10, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4506, 306, 12, 10, 0.10, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4507, 306, 4, 30, 0.30, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4508, 306, 9, 50, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4509, 307, 12, 60, 3.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4510, 307, 13, 30, 1.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4511, 307, 9, 10, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4512, 309, 3, 90, 2.70, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4513, 309, 9, 10, 0.30, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4514, 310, 3, 100, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4515, 313, 12, 85, 4.25, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4516, 313, 9, 15, 0.75, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4517, 314, 12, 60, 0.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4518, 314, 13, 35, 0.35, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4519, 314, 9, 5, 0.05, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4520, 315, 3, 100, 3.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4521, 316, 4, 10, 0.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4522, 316, 13, 40, 0.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4523, 316, 9, 50, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4524, 317, 13, 50, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4525, 317, 9, 50, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4526, 318, 13, 50, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4527, 318, 9, 50, 0.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4528, 319, 3, 70, 2.10, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4529, 319, 9, 30, 0.90, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4530, 320, 3, 90, 2.70, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4531, 320, 9, 10, 0.30, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4532, 321, 4, 100, 3.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4533, 322, 9, 75, 1.50, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4534, 322, 4, 15, 0.30, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4535, 322, 3, 10, 0.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4536, 323, 12, 25, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4537, 323, 13, 75, 3.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4538, 324, 13, 100, 2.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4539, 325, 3, 100, 3.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4540, 326, 4, 100, 3.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4541, 327, 4, 72, 2.88, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4542, 327, 13, 20, 0.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4543, 327, 2, 8, 0.32, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4544, 329, 9, 100, 3.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4545, 331, 13, 60, 1.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4546, 331, 4, 30, 0.90, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4547, 331, 9, 10, 0.30, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4548, 332, 12, 10, 0.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4549, 332, 4, 40, 0.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4550, 332, 9, 50, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4551, 333, 13, 100, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4552, 334, 9, 20, 0.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4553, 334, 3, 80, 2.40, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4554, 336, 3, 80, 3.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4555, 336, 9, 20, 0.80, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4556, 337, 9, 10, 0.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4557, 337, 12, 60, 1.20, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4558, 337, 3, 30, 0.60, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4559, 339, 9, 50, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4560, 339, 13, 50, 1.00, '2025-11-21 21:37:59', '2025-11-21 21:37:59'),
(4590, 341, 9, 8, 0.32, '2025-11-21 22:08:24', '2025-11-21 22:08:24'),
(4591, 341, 4, 46, 1.84, '2025-11-21 22:08:24', '2025-11-21 22:08:24'),
(4592, 341, 13, 46, 1.84, '2025-11-21 22:08:24', '2025-11-21 22:08:24'),
(4593, 398, 9, 55, 0.55, '2025-11-21 22:29:01', '2025-11-21 22:29:01'),
(4594, 398, 4, 35, 0.35, '2025-11-21 22:29:01', '2025-11-21 22:29:01'),
(4595, 398, 12, 5, 0.05, '2025-11-21 22:29:01', '2025-11-21 22:29:01'),
(4596, 398, 3, 5, 0.05, '2025-11-21 22:29:01', '2025-11-21 22:29:01'),
(4600, 401, 9, 10, 0.30, '2025-11-26 22:27:31', '2025-11-26 22:27:31'),
(4601, 401, 3, 90, 2.70, '2025-11-26 22:27:31', '2025-11-26 22:27:31'),
(4603, 402, 12, 85, 1.70, '2025-11-26 23:24:32', '2025-11-26 23:24:32'),
(4604, 402, 3, 10, 0.20, '2025-11-26 23:24:32', '2025-11-26 23:24:32'),
(4605, 402, 9, 5, 0.10, '2025-11-26 23:24:32', '2025-11-26 23:24:32'),
(4606, 340, 9, 50, 1.00, '2025-11-27 00:01:45', '2025-11-27 00:01:45'),
(4607, 340, 3, 25, 0.50, '2025-11-27 00:01:45', '2025-11-27 00:01:45'),
(4608, 340, 13, 25, 0.50, '2025-11-27 00:01:45', '2025-11-27 00:01:45'),
(4615, 400, 4, 95, 1.90, '2025-11-27 19:12:40', '2025-11-27 19:12:40'),
(4616, 400, 9, 5, 0.10, '2025-11-27 19:12:40', '2025-11-27 19:12:40'),
(4618, 342, 4, 60, 3.00, '2025-11-27 19:45:52', '2025-11-27 19:45:52'),
(4619, 342, 13, 35, 1.75, '2025-11-27 19:45:52', '2025-11-27 19:45:52'),
(4620, 342, 9, 5, 0.25, '2025-11-27 19:45:52', '2025-11-27 19:45:52'),
(4621, 312, 9, 10, 0.10, '2025-11-27 20:23:56', '2025-11-27 20:23:56'),
(4622, 312, 3, 90, 0.90, '2025-11-27 20:23:56', '2025-11-27 20:23:56'),
(4624, 311, 3, 90, 1.80, '2025-11-27 20:27:48', '2025-11-27 20:27:48'),
(4625, 311, 9, 10, 0.20, '2025-11-27 20:27:48', '2025-11-27 20:27:48'),
(4630, 404, 9, 67, 3.35, '2025-11-27 20:32:43', '2025-11-27 20:32:43'),
(4631, 404, 3, 33, 1.65, '2025-11-27 20:32:43', '2025-11-27 20:32:43'),
(4633, 403, 9, 50, 3.50, '2025-11-27 20:33:25', '2025-11-27 20:33:25'),
(4634, 403, 3, 50, 3.50, '2025-11-27 20:33:25', '2025-11-27 20:33:25'),
(4636, 405, 9, 60, 1.20, '2025-11-27 20:36:55', '2025-11-27 20:36:55'),
(4637, 405, 13, 30, 0.60, '2025-11-27 20:36:55', '2025-11-27 20:36:55'),
(4638, 405, 3, 10, 0.20, '2025-11-27 20:36:55', '2025-11-27 20:36:55'),
(4639, 406, 13, 50, 1.00, '2025-11-27 20:58:16', '2025-11-27 20:58:16'),
(4640, 406, 4, 45, 0.90, '2025-11-27 20:58:16', '2025-11-27 20:58:16'),
(4641, 406, 9, 5, 0.10, '2025-11-27 20:58:16', '2025-11-27 20:58:16'),
(4642, 407, 13, 100, 2.00, '2025-11-27 21:26:52', '2025-11-27 21:26:52'),
(4643, 408, 13, 100, 4.00, '2025-11-28 16:56:34', '2025-11-28 16:56:34'),
(4644, 409, 4, 100, 3.00, '2025-11-28 17:00:34', '2025-11-28 17:00:34'),
(4645, 410, 9, 50, 1.50, '2025-11-28 17:54:58', '2025-11-28 17:54:58'),
(4646, 410, 3, 50, 1.50, '2025-11-28 17:54:58', '2025-11-28 17:54:58'),
(4648, 411, 9, 100, 1.00, '2025-11-28 17:58:00', '2025-11-28 17:58:00'),
(4652, 328, 9, 40, 0.80, '2025-11-28 19:12:31', '2025-11-28 19:12:31'),
(4653, 328, 3, 60, 1.20, '2025-11-28 19:12:31', '2025-11-28 19:12:31'),
(4655, 345, 9, 100, 1.00, '2025-11-28 19:12:55', '2025-11-28 19:12:55'),
(4656, 344, 4, 50, 0.50, '2025-11-28 19:15:15', '2025-11-28 19:15:15'),
(4657, 344, 3, 50, 0.50, '2025-11-28 19:15:15', '2025-11-28 19:15:15'),
(4659, 338, 3, 65, 0.65, '2025-11-28 19:30:32', '2025-11-28 19:30:32'),
(4660, 338, 4, 10, 0.10, '2025-11-28 19:30:32', '2025-11-28 19:30:32'),
(4661, 338, 9, 25, 0.25, '2025-11-28 19:30:32', '2025-11-28 19:30:32'),
(4662, 330, 13, 28, 1.12, '2025-11-28 19:38:35', '2025-11-28 19:38:35'),
(4663, 330, 9, 32, 1.28, '2025-11-28 19:38:35', '2025-11-28 19:38:35'),
(4664, 330, 4, 40, 1.60, '2025-11-28 19:38:35', '2025-11-28 19:38:35'),
(4665, 412, 13, 95, 1.90, '2025-11-28 20:05:57', '2025-11-28 20:05:57'),
(4666, 412, 9, 5, 0.10, '2025-11-28 20:05:57', '2025-11-28 20:05:57'),
(4668, 413, 9, 5, 0.10, '2025-11-28 20:07:04', '2025-11-28 20:07:04'),
(4669, 413, 13, 95, 1.90, '2025-11-28 20:07:04', '2025-11-28 20:07:04'),
(4671, 399, 13, 10, 0.20, '2025-11-28 21:11:57', '2025-11-28 21:11:57'),
(4672, 399, 4, 90, 1.80, '2025-11-28 21:11:57', '2025-11-28 21:11:57'),
(4674, 414, 9, 50, 1.00, '2025-11-28 23:17:36', '2025-11-28 23:17:36'),
(4675, 414, 3, 50, 1.00, '2025-11-28 23:17:36', '2025-11-28 23:17:36'),
(4677, 415, 3, 50, 0.50, '2025-12-01 16:13:54', '2025-12-01 16:13:54'),
(4678, 415, 9, 50, 0.50, '2025-12-01 16:13:54', '2025-12-01 16:13:54'),
(4680, 343, 12, 40, 2.40, '2025-12-01 16:15:08', '2025-12-01 16:15:08'),
(4681, 343, 3, 40, 2.40, '2025-12-01 16:15:08', '2025-12-01 16:15:08'),
(4682, 343, 9, 20, 1.20, '2025-12-01 16:15:08', '2025-12-01 16:15:08'),
(4683, 308, 9, 40, 0.80, '2025-12-01 21:03:13', '2025-12-01 21:03:13'),
(4684, 308, 3, 60, 1.20, '2025-12-01 21:03:13', '2025-12-01 21:03:13'),
(4686, 417, 9, 50, 0.50, '2025-12-02 19:16:18', '2025-12-02 19:16:18'),
(4687, 417, 4, 10, 0.10, '2025-12-02 19:16:18', '2025-12-02 19:16:18'),
(4688, 417, 3, 40, 0.40, '2025-12-02 19:16:18', '2025-12-02 19:16:18'),
(4689, 420, 3, 85, 2.55, '2025-12-03 23:14:06', '2025-12-03 23:14:06'),
(4690, 420, 13, 5, 0.15, '2025-12-03 23:14:06', '2025-12-03 23:14:06'),
(4691, 420, 9, 10, 0.30, '2025-12-03 23:14:06', '2025-12-03 23:14:06'),
(4692, 418, 3, 75, 3.00, '2025-12-04 00:45:03', '2025-12-04 00:45:03'),
(4693, 418, 9, 15, 0.60, '2025-12-04 00:45:03', '2025-12-04 00:45:03'),
(4694, 418, 13, 10, 0.40, '2025-12-04 00:45:03', '2025-12-04 00:45:03'),
(4695, 423, 3, 100, 1.00, '2025-12-04 14:17:39', '2025-12-04 14:17:39'),
(4696, 428, 4, 100, 3.00, '2025-12-04 17:04:48', '2025-12-04 17:04:48'),
(4697, 429, 4, 80, 2.40, '2025-12-04 17:21:19', '2025-12-04 17:21:19'),
(4698, 429, 9, 20, 0.60, '2025-12-04 17:21:19', '2025-12-04 17:21:19'),
(4700, 430, 12, 90, 1.80, '2025-12-04 17:31:26', '2025-12-04 17:31:26'),
(4701, 430, 9, 10, 0.20, '2025-12-04 17:31:26', '2025-12-04 17:31:26'),
(4703, 431, 9, 55, 0.55, '2025-12-04 17:37:22', '2025-12-04 17:37:22'),
(4704, 431, 4, 45, 0.45, '2025-12-04 17:37:22', '2025-12-04 17:37:22');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `empleado`
--

CREATE TABLE `empleado` (
  `idempleado` int(11) NOT NULL,
  `nombres` varchar(100) NOT NULL,
  `paterno` varchar(50) NOT NULL,
  `materno` varchar(50) NOT NULL,
  `nombrecorto` varchar(50) DEFAULT NULL,
  `dni` varchar(10) NOT NULL,
  `nacimiento` date NOT NULL,
  `lugarnacimiento` varchar(100) NOT NULL,
  `domicilio` varchar(150) NOT NULL,
  `estadocivil` varchar(50) NOT NULL,
  `correopersonal` varchar(100) NOT NULL,
  `correocorporativo` varchar(100) NOT NULL,
  `telcelular` varchar(15) NOT NULL,
  `telfijo` varchar(10) NOT NULL,
  `horasmeta` int(11) NOT NULL DEFAULT 30,
  `area` varchar(50) NOT NULL,
  `cargo` varchar(50) NOT NULL,
  `derechohabiente` varchar(50) NOT NULL,
  `cantidadhijos` int(11) NOT NULL,
  `contactoemergencia` varchar(100) NOT NULL,
  `nivelestudios` varchar(50) NOT NULL,
  `regimenpension` varchar(50) NOT NULL,
  `fondopension` varchar(50) NOT NULL,
  `cussp` varchar(50) NOT NULL,
  `modalidad` varchar(50) NOT NULL,
  `rutafoto` varchar(250) NOT NULL,
  `activo` int(11) NOT NULL,
  `editor` int(11) NOT NULL DEFAULT 0,
  `registrado` timestamp NOT NULL DEFAULT current_timestamp(),
  `modificado` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `empleado`
--

INSERT INTO `empleado` (`idempleado`, `nombres`, `paterno`, `materno`, `nombrecorto`, `dni`, `nacimiento`, `lugarnacimiento`, `domicilio`, `estadocivil`, `correopersonal`, `correocorporativo`, `telcelular`, `telfijo`, `horasmeta`, `area`, `cargo`, `derechohabiente`, `cantidadhijos`, `contactoemergencia`, `nivelestudios`, `regimenpension`, `fondopension`, `cussp`, `modalidad`, `rutafoto`, `activo`, `editor`, `registrado`, `modificado`) VALUES
(1, 'Kelly Yajaira', 'Renquifo', 'Cieza', 'Kelly', '47962973', '1993-09-05', 'Hualgayoc, Cajamarca', 'Jr. Trinidad 295, Dpto 301, Urb. Villa Jardin, San Luis, Lima', 'Soltera', 'k.renquifo@gmail.com', 'kelly.renquifo@ampara.pe', '951600532', 'No Aplica', 30, '', '', 'No Aplica', 0, 'Flor Cieza Infante - Madre - 971792154', 'Bachiller en Derecho', 'AFP', 'PRIMA', '342150KRCQZ1', 'Planilla', 'img/fotos/empleados/Kelly.png', 0, 0, '2025-07-02 16:00:21', '2025-07-02 16:00:21'),
(2, 'Maria Lucia Margot', 'Gonzalez', 'Soto', 'Malú', '70774300', '1999-05-24', 'Miraflores, Lima', 'Curazao 385, La Molina', 'Soltero', 'malumags@gmail.com', 'marialucia.gonzalez@ampara.pe', '980362757', 'No Aplica', 5, 'Recursos Humanos', 'Asociado', 'No aplica', 0, 'Victor Humberto Gonzalez Acuña | Padre | 999106985', 'Bachiller', 'AFP', 'INTEGRA', '663020MGSZO8', 'Planilla', 'img/fotos/empleados/Maria.png', 1, 2, '2025-07-02 16:00:21', '2025-11-28 13:40:48'),
(3, 'Jacy Sarahi', 'Rojas', 'Pasapera', 'Jacy', '72667251', '2000-04-30', 'Piura, Piura', 'Av. Benjamin Franklin 576, Ate', 'Soltera', 'jacyrp72667251@gmail.com', 'jacy.rojas@ampara.pe', '963587885', 'No Aplica', 30, '', '', 'No Aplica', 0, 'JACINTA PASAPERA PINTADO | MAMÁ | 928153463', 'Bachiller en Ingeniería Electrónica y de Telecomun', 'AFP', 'INTEGRA', '666440JRPAA4', 'Planilla', 'img/fotos/empleados/Jacy.png', 1, 0, '2025-07-02 16:00:21', '2025-07-02 16:00:21'),
(4, 'Gustavo Vittorio', 'Ramirez', 'Sanchez', 'Gustavo', '75310964', '1998-07-25', 'Miraflores, Lima', 'Sector 03 - Grupo 15 Mz. B Lote 3, Villa El Salvador								', 'Soltero', 'asdafe25@gmail.com', 'gustavo.ramirez@ampara.pe', '944340916', 'No Aplica', 30, '', '', 'No Aplica', 0, 'Victorio Ramirez Sánchez | Padre | 949231482', 'Bachiller en Derecho', 'AFP', 'INTEGRA', '659991GRSIC6', 'Planilla', 'img/fotos/empleados/Gustavo.png', 1, 0, '2025-07-02 16:00:21', '2025-07-02 16:00:21'),
(5, 'Katy Andrea', 'Nieto', 'Casafranca', 'Katy', '72369959', '1997-12-09', 'Santiago, Cusco', 'Calle Chacabuco Nº 185, Torre Nº 8 y departamento Nº 1207, San Miguel', 'Soltera', 'katy.nieto@pucp.edu.pe', 'katy.nieto@ampara.pe', '982049282', 'No Aplica', 30, '', '', 'No Aplica', 0, '', 'Bachiller en Derecho', 'AFP', 'INTEGRA', '657710KNCTA9', 'Planilla', 'img/fotos/empleados/Katy.png', 0, 2, '2025-07-02 16:00:21', '2025-08-15 18:20:58'),
(6, 'Janira Samajuto', 'Torres', 'Cuadros', 'Janira', '48137494', '1994-02-23', 'Huamanga, Ayacucho', 'Duque de la Palata 157, Surco', 'Soltera', 'janira_torres_@outlook.com', 'janira.torres@ampara.pe', '994341934', 'No Aplica', 30, '', '', 'No Aplica', 0, 'TORRES CUADROS TONY | HERMANO | 920 877 844	', 'Titulada en Derecho', 'AFP', 'INTEGRA', '643860JTCRD0', 'Planilla', 'img/fotos/empleados/Janira.png', 0, 2, '2025-07-02 16:00:21', '2025-09-08 16:00:21'),
(7, 'David Gustavo', 'Roque', 'Mamani', 'David', '72682491', '1994-11-01', 'Yanahuara, Arequipa', 'Rafael Aedo Guerrero Mz Z1 Lote 6, Surco', 'Soltera', 'davidgroquem@gmail.com', 'david.roque@ampara.pe', '974438885', 'No Aplica', 30, '', '', 'No Aplica', 0, 'Flores Turpo Fancy Noemi | Conviviente | 955713507', 'Bachiller en Ingeniería de Telecomunicaciones', 'AFP', 'PRIMA', '646371DRMUA9', 'Planilla', 'img/fotos/empleados/David.png', 0, 0, '2025-07-02 16:00:21', '2025-07-02 16:00:21'),
(8, 'Juan Carlos', 'Cornejo', 'Cuzzi', 'Socios', '10286953', '1977-03-07', 'Lima', 'Miraflores, Lima', 'Casado', 'jccornejocuzzi@gmail.com', 'juancarlos.cornejo@ampara.pe', '996291396', 'No Aplica', 30, '', '', 'No Aplica', 0, '', 'Abogado Colegiado', 'AFP', 'PRIMA', '581891JCCNZ0', 'Recibo por Honorarios', 'img/fotos/empleados/Juan_Carlos.png', 0, 2, '2025-07-02 16:00:21', '2025-08-22 13:49:29'),
(9, 'Gino Christian', 'Kou', 'Reyna', 'Socios', '10288581', '1977-05-17', 'Lima', 'Surco, Lima', 'Casado', '', 'gino.kou@ampara.pe', '995731361', 'No Aplica', 30, '', '', 'No Aplica', 0, '', 'Ingeniero Colegiado', 'AFP', 'HABITAT', '582601GKRUN1', 'Recibo por Honorarios', 'img/fotos/empleados/Gino.png', 1, 0, '2025-07-02 16:00:21', '2025-07-02 16:00:21'),
(10, 'Maria Laura', 'Yataco', 'Cornejo', 'Maria Laura', '07628964', '0000-00-00', '', 'Calle 28 de Julio 535 Dpto 302, Magdalena del Mar', '', 'marialaura.yataco@gmail.com', '', '975590975', '', 30, '', '', '', 0, '', '', 'AFP', 'PRIMA', '566820MYCAN2', 'Recibo por Honorarios', 'img/fotos/empleados/Milena.png', 0, 0, '2025-07-02 16:00:21', '2025-07-02 16:00:21'),
(11, 'Hugo', 'Oré', 'Julca', 'Hugo', '10650100', '0980-07-22', 'PL', 'QW', 'Soltero', 'hcorej@gmail.com', 'hcorej@gmail.com', '993658576', '543541231', 20, 'Recursos Humanos', 'Asociado', 'No aplica', 1, '993658576', 'Bachiller', 'AFP', 'INTEGRA', 'UTYURTYU', 'Recibo por Honorarios', 'img/fotos/empleados/Hugo.PNG', 0, 11, '2025-07-23 00:03:28', '2025-11-28 10:36:07'),
(12, 'Paolo Angelo', 'Conde', 'Cadillo', 'Paolo', '72185975', '2000-02-12', 'LIMA', 'Av. San Luis 3202', 'Soltero', 'paolocondec@gmail.com', 'paolo.conde@ampara.pe', '967129279', '', 23, 'Técnico Regulatorio', 'Asociado', 'No aplica', 0, 'CONDE CADILLO ANGEL ANDRE MIGUEL | HERMANO | 990168604', 'Bachiller', 'AFP', 'OTRO', 'SOLICITADO', 'Planilla', 'img/fotos/empleados/3-FotoFormal_PaoloConde.jpg', 1, 2, '2025-10-06 17:05:34', '2025-12-01 21:03:28'),
(13, 'Evelyn', 'Castro', '-', 'Evelyn', '0', '2025-10-06', '0', 's', 'Soltero', 's@gmail.com', 's@gmail.com', 's', '', 23, 'Legal Regulatorio', 'Socio Fundador', 'No aplica', 0, 's', 'Abogado', 'OTRO', 'OTRO', '', 'Recibo por Honorarios', 'img/fotos/empleados/Evelyn.png', 1, 2, '2025-10-13 14:46:37', '2025-12-01 21:04:15');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `evento`
--

CREATE TABLE `evento` (
  `idevento` int(11) NOT NULL,
  `titulo` varchar(100) NOT NULL,
  `descripcion` varchar(500) NOT NULL,
  `colorfondo` varchar(25) NOT NULL,
  `colortexto` varchar(25) NOT NULL,
  `url` varchar(150) NOT NULL,
  `fechainicio` date NOT NULL,
  `fechafin` date NOT NULL,
  `lider` int(11) NOT NULL,
  `acargode` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `facturacion`
--

CREATE TABLE `facturacion` (
  `idfacturacion` int(11) NOT NULL,
  `fecha` date NOT NULL,
  `codigo` varchar(50) NOT NULL,
  `horasgen` varchar(50) NOT NULL,
  `tipocliente` varchar(50) NOT NULL,
  `status` varchar(50) NOT NULL,
  `moneda` varchar(50) NOT NULL,
  `cambiosunat` decimal(5,2) NOT NULL,
  `tiposervicio` varchar(50) NOT NULL,
  `idcliente` int(11) NOT NULL,
  `subtotal` decimal(7,2) NOT NULL,
  `igv` decimal(7,2) NOT NULL,
  `total` decimal(7,2) NOT NULL,
  `detraccion` decimal(7,2) NOT NULL,
  `netosindetrac` decimal(7,2) NOT NULL,
  `fechaemision` date NOT NULL,
  `fechaenvio` date NOT NULL,
  `fechapago` date NOT NULL,
  `fechapagodetrac` date NOT NULL,
  `comentarios` varchar(500) NOT NULL,
  `mesemision` date NOT NULL,
  `mescobrado` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `liquidacion`
--

CREATE TABLE `liquidacion` (
  `idliquidacion` int(11) NOT NULL,
  `fecha` date NOT NULL,
  `asunto` varchar(1500) NOT NULL,
  `tema` int(11) NOT NULL,
  `motivo` mediumtext NOT NULL,
  `tipohora` varchar(45) NOT NULL,
  `acargode` int(11) NOT NULL,
  `lider` int(11) NOT NULL,
  `cantidahoras` int(11) NOT NULL,
  `estado` varchar(50) NOT NULL,
  `idcontratocli` int(11) NOT NULL,
  `idpresupuesto` int(11) NOT NULL,
  `activo` int(11) NOT NULL,
  `editor` int(11) NOT NULL DEFAULT 1,
  `enlace_onedrive` text DEFAULT NULL,
  `fecha_completo` date DEFAULT NULL,
  `registrado` timestamp NOT NULL DEFAULT current_timestamp(),
  `modificado` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `liquidacion`
--

INSERT INTO `liquidacion` (`idliquidacion`, `fecha`, `asunto`, `tema`, `motivo`, `tipohora`, `acargode`, `lider`, `cantidahoras`, `estado`, `idcontratocli`, `idpresupuesto`, `activo`, `editor`, `enlace_onedrive`, `fecha_completo`, `registrado`, `modificado`) VALUES
(4, '2025-05-02', 'Análisis y revisión', 12, 'Elaboración de ficha de registro de nueva tarifa establecida por servicio de internet 1000 Mbps para clientes de MiFibra, indicando sus respectivas condiciones y restricciones. Asimismo, se realizó adecuaciones a la tarifa promocional por el servicio de internet 500 Mbps. Se brindaron recomendaciones y sugerencias ante los dos casos planteados para evaluación del cliente.', 'Soporte', 4, 4, 2, 'Completo', 1, 0, 1, 1, NULL, NULL, '2025-06-18 04:56:07', '2025-06-18 04:56:07'),
(5, '2025-05-13', 'Análisis y revisión', 6, 'Búsqueda, revisión y análisis de jurisprudencia de OSIPTEL vinculada a casuística de uso indebido, en base a la cual, se enviaron recomendaciones a CALA respecto de la implementación de sus protocolos para la detección y acreditación de casos de uso indebido de los servicios públicos de telecomunicaciones.', 'Soporte', 4, 4, 2, 'Completo', 1, 0, 1, 1, NULL, NULL, '2025-06-18 04:57:14', '2025-06-18 04:57:14'),
(6, '2025-05-30', 'Horas audio', 1, 'Seguimiento y consulta con OSIPTEL de solicitud de acceso a la información pública sobre detalles financieros de WIN y WOW (15.05.2025) // Llamada de Jorge Araujo con Juan Carlos para absolver consultas sobre plazo forzoso y resolución de contratos (20.05.2025) // Envío a cliente de información remitida por OSIPTEL en respuesta a solicitud de acceso a la información pública (20.05.2025).', 'Soporte', 5, 4, 1, 'Completo', 1, 0, 1, 1, NULL, NULL, '2025-06-18 04:59:56', '2025-06-18 04:59:56'),
(7, '2025-05-16', 'Reunión', 14, 'Reunión de revisión de pendientes.', 'Soporte', 6, 6, 1, 'Completo', 2, 0, 1, 1, NULL, NULL, '2025-06-18 05:01:13', '2025-06-18 05:01:13'),
(8, '2025-05-23', 'Análisis y revisión', 14, '- Revisión y análisis de la Carta N° 000184-2025-DPRC/OSIPTEL de OSIPTEL donde nos traslada los comentarios de Telefónica.\r\n- Elaboración de propuesta de respuesta a la carta del OSIPTEL donde se fundamentó legal y jurisprudencialmente la correcta aplicación del artículo 7 de las “NORMAS COMPLEMENTARIAS APLICABLES A LOS OPERADORES MÓVILES VIRTUALES” (RCD Nº 009-2016-CD/OSIPTEL); asimismo, se elaboraron diagramas de topología de red para darle mayor peso a la carta.', 'Soporte', 6, 6, 5, 'Completo', 2, 0, 1, 1, NULL, NULL, '2025-06-18 05:03:00', '2025-06-18 05:03:00'),
(9, '2025-05-27', 'Análisis y revisión', 23, 'Elaboración de carta para dar respuesta a la solicitud de información respecto a los compromisos establecidos a DOLPHIN en el proceso de\r\nreordenamiento de la banda de frecuencias 2 300 – 2 400 MHz realizada por el MTC.', 'Soporte', 3, 6, 2, 'Completo', 2, 0, 1, 1, NULL, NULL, '2025-06-18 05:04:20', '2025-06-18 05:04:20'),
(10, '2025-05-29', 'Horas audio', 1, 'Reuniones de coordinación (varias) entre Gino y Juan Carlos con Javier y César.', 'Soporte', 5, 6, 1, 'Completo', 2, 0, 1, 1, NULL, NULL, '2025-06-18 05:06:32', '2025-06-18 05:06:32'),
(11, '2025-05-29', 'Reunión', 1, 'Reunión respecto a la elaboración de medios probatorios que complementen la carta de respuesta al requerimiento de información del MTC (reordenamiento de bandas).', 'Soporte', 5, 6, 1, 'Completo', 2, 0, 1, 1, NULL, NULL, '2025-06-18 05:07:41', '2025-06-18 05:07:41'),
(12, '2025-05-06', 'Reunión', 15, 'Reunión para revisar lo precisado por el OSIPTEL en el mandato complementario de acceso entre INTERMAX y BITEL, y las actividades a seguir  para la implementación total del servicio.', 'Soporte', 6, 3, 1, 'Completo', 5, 0, 1, 1, NULL, NULL, '2025-06-18 05:09:08', '2025-06-18 05:09:08'),
(13, '2025-05-07', 'Reunión', 14, 'Reunión respecto a la respuesta de la Orden de Servicio por SMS enviadas a BITEL.', 'Soporte', 6, 6, 1, 'Completo', 4, 0, 1, 1, NULL, NULL, '2025-07-02 15:29:47', '2025-07-04 07:55:46'),
(14, '2025-05-09', 'Reunión', 14, 'Acompañamiento en la reunión de coordinación técnica con el equipo de BITEL a propósito de la OS por SMS enviada.', 'Soporte', 6, 6, 1, 'Completo', 4, 0, 1, 1, NULL, NULL, '2025-07-02 15:38:42', '2025-07-02 15:39:44'),
(15, '2025-05-09', 'Análisis y revisión', 25, 'Analisis y revisión de consulta respecto a la subsanación voluntaria de formatos establecidos en la NEIP, revisión de plazos establecidos, condiciones y mecanismos empleados. Analisis y elaboración estratégica frente a una posible sanción por la no presentación de los formatos en los 3 ultimos trimestres. Investigación sobre mecanismos empleados y las comunicaciones trasladadas por el OSIPTEL a los OMV.', 'Soporte', 3, 3, 3, 'Completo', 5, 0, 1, 1, NULL, NULL, '2025-07-02 15:41:45', '2025-07-02 15:41:45'),
(16, '2025-05-09', 'Análisis y revisión', 15, '\"Matriz-resumen de las disposiciones aprobadas mediante Mandato Complementario (coubicación) y las propuestas del Proyecto de Mandato y los comentarios presentados al respecto.\r\n\r\nIncluye lectura y analisis del proyecto del mandato y del mandato final emitido por el OSIPTEL \"', 'Soporte', 6, 3, 2, 'Completo', 5, 0, 1, 1, NULL, NULL, '2025-07-02 15:43:31', '2025-07-02 15:43:31'),
(17, '2025-05-09', 'Análisis y revisión', 15, '\"Análisis, revisión y modificación de proyecto de carta para BITEL para solicitar \r\n(i) la habilitación de la numeración asignada a INTERMAX en la red de BITEL \r\n(ii) la notificación correspondiente a los operadores con los cuales BITEL mantiene relaciones de interconexión\r\n(iii) la culminación de todas las configuraciones técnicas necesarias para permitir el acceso efectivo y operativo de los servicios de INTERMAX (Voz y SMS) a la red de BITEL.\r\n\r\nIncluye el análisis de los antecedentes (actas ', 'Soporte', 6, 3, 4, 'Completo', 5, 0, 1, 1, NULL, NULL, '2025-07-02 15:44:51', '2025-07-02 15:44:51'),
(18, '2025-05-13', 'Reunión', 14, '\"Reunión de acompañamiento para acción de fiscalización del OSIPTEL por el posible incumplimiento a la Medida Correctiva impuesta a BITEL. \r\nApoyo en elaboración de actas, establecer escenarios de pruebas y detalle de comentarios\"', 'Soporte', 6, 3, 9, 'Completo', 5, 0, 1, 1, NULL, NULL, '2025-07-02 15:54:03', '2025-07-02 15:54:03'),
(19, '2025-05-16', 'Análisis y revisión', 15, 'Absolución de consulta respecto la solicitud de la facturación por la implementación del acceso con BITEL y actualización de carta. Además evaluación de plazos establecidos en el mandato de acceso y mandato complementario.', 'Soporte', 6, 3, 2, 'Completo', 5, 0, 1, 1, NULL, NULL, '2025-07-02 15:56:16', '2025-07-02 15:56:16'),
(20, '2025-05-23', 'Análisis y revisión', 14, '- Revisión y análisis de la  Carta DMR-CE-1378-25 de CLARO mediante la cual se pronunció sobre la solicitud de interconexión de telefonía+ transporte, a través de protocolo SIP, y SMS.\r\n- Elaboración de propuesta de respuesta a la carta de CLARO donde, principalmente, se cuestionó (bajo fundamento legal y jurisprudencial) la posición de rechazo de CLARO sobre la solicitud de SMS bajo cualquier modalidad que contemple aplicativo.\r\n- Atención a los correos y mensajes posteriores al respecto.', 'Soporte', 6, 6, 4, 'Completo', 4, 0, 1, 1, NULL, NULL, '2025-07-02 15:57:49', '2025-07-02 15:57:49'),
(21, '2025-05-23', 'Reunión', 26, 'Reunión para absolver consultas respecto a la fiscalización por el uso del MNC en los servicios fijo y de OMV a cargo de MTC ', 'Soporte', 3, 3, 1, 'Completo', 5, 0, 1, 1, NULL, NULL, '2025-07-02 16:00:09', '2025-07-02 16:00:09'),
(22, '2025-05-26', 'Horas audio', 14, '- Llamada previa de coordinación con Rafael para la reunión de acompañamiento con BITEL (cronograma de actividades).\r\n- Llamada de coordinación con Rafael sobre los siguientes pasos en asuntos de interconexión a propósito de la reunión de acompañamiento.\r\n- Revisión de la orden de servicio por llamada (SIP), revisión del Mandato de interconexión con Bitel y la normativa de interconexión a fin de validar su correcto envío por el equipo de Fibermax. Se identificó y alertó (mediante llamada del 12.', 'Soporte', 6, 6, 3, 'Completo', 4, 0, 1, 1, NULL, NULL, '2025-07-02 16:02:16', '2025-07-02 16:02:16'),
(23, '2025-05-28', 'Análisis y revisión', 1, 'Absolución de consulta y emisión de recomendaciones respecto de las acciones a seguir por INTERMAX ante la imposibilidad de continuar compensando sus pagos por cargos de interconexión ante TELEFÓNICA, como resultado del inicio de su procedimiento concursal, en función de la normativa concursal y regulatoria aplicable.', 'Soporte', 5, 3, 2, 'Completo', 5, 0, 1, 1, NULL, NULL, '2025-07-02 16:03:33', '2025-07-02 16:03:33'),
(24, '2025-07-04', 'Reunión', 15, 'Reunión de coordinación para establecer una estrategia frente a la implementación del acceso con BITEL; además se absolvieron consultas respecto al riesgo regulatorio por contemplara el grupo económico de INTERMAX en la carta a BITEL por bloqueo a la interconexión y acceso ', 'Soporte', 6, 3, 2, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-07-02 16:04:50', '2025-07-04 21:11:27'),
(25, '2025-05-30', 'Análisis y revisión', 14, '\"- Revisión de la Orden de Servicio N° FBX-0002 (OS) vinculado al servicio de llamadas - SIP.\r\n- Revisión y análisis de los alcances de la carta N° 0606-2024/GL.CDR de BITEL donde observa la OS emitida.\r\n- Elaboración de proyecto de respuesta a la carta de BITEL y elaboración de nueva Orden de Servicio para llamadas - SIP.\"', 'Soporte', 6, 6, 2, 'Completo', 4, 0, 1, 1, NULL, NULL, '2025-07-02 16:05:54', '2025-07-02 16:05:54'),
(26, '2025-05-30', 'Horas audio', 14, 'Audio con Osiptel respecto a los formatos aplicables para el cumplimiento del NEIP | Reunión con Rafael al mediodía para evaluar status de fiscalización (al mediodía) | Reunión con Marcelo al culminar la fiscalización para evaluar posición frente a los posibles resultados de la evaluación de OSIPTEL | Audio con Kattya, respecto a la fiscalización de MNC por parte del OSIPTEL (29-05-25)', 'Soporte', 6, 3, 2, 'Completo', 5, 0, 1, 1, NULL, NULL, '2025-07-02 16:07:30', '2025-07-02 16:07:30'),
(30, '2025-07-02', 'Análisis y revisión', 15, 'Comentarios al proyecto de mandato de OMV con ENTEL, se realizó una lectura integral del documento para mapear puntos a comentar y posteriormente precisar los que tendría una mayor viabilidad y consistencia con la situación actual de INTERMAX.  S e evaluaron antecedentes para mapear relaciones de acceso de ENTEL con otros OMV; además se realizó análisis de costos actuales que INTERMAX mantiene con otros OMR y los cargos que sería aplicables asociados a la ORMV', 'Soporte', 6, 3, 4, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-07-02 18:37:55', '2025-07-04 21:17:01'),
(31, '2025-07-02', 'Análisis y revisión', 12, 'Atención de consulta de Javier Sánchez sobre obligación de DOLPHIN para comunicar al OSIPTEL (a través del SIRT u otro mecanismo) las tarifas mayoristas que ofrecen a sus comercializadores. Se analizó normativa regulatoria vigente en materia tarifaria y documentos asociados (informe de sustento y exposición de motivos), así como también a nivel histórico (normativa derogada).', 'Soporte', 4, 6, 2, 'Completo', 2, 0, 1, 1, NULL, NULL, '2025-07-03 00:38:35', '2025-07-03 00:49:53'),
(32, '2025-07-02', 'Reunión', 13, 'Reunión solicitada por Julio Cieza, en compañía de Giovanna Piskulich y Angélica Chumpitaz, para abordar el caso advertido en Arequipa sobre uso indebido por parte de INTEGRATEL del servicio de arrendamiento de circuitos. Se brindaron alcances en base a la norma y alternativas de acción ante a OSIPTEL.', 'Soporte', 4, 4, 1, 'Completo', 6, 0, 1, 1, NULL, NULL, '2025-07-03 01:21:50', '2025-07-03 01:21:50'),
(33, '2025-07-02', 'Reunión', 19, 'Joana solicitó una reunión para revisar, de modo general, los proyectos de su área de tecnología admisibles en las categorías de innovación y cierre de brechas del SANDBOX REGULATORIO. Se precisaron las directrices legales-generales. Se añadieron consideraciones técnicas en caso se usen bandas no licenciadas. Se recomendó guiarse de la matriz resumen enviada, hacer énfasis en los impedimentos, mapear las consideraciones técnicas y guiarse del cuestionario para la admisión de cada proyecto.', 'Soporte', 6, 6, 1, 'Completo', 3, 0, 1, 6, NULL, NULL, '2025-07-03 18:03:17', '2025-07-25 21:53:44'),
(35, '2025-07-02', 'Análisis y revisión', 33, 'Sheyla nos solicitó atender la Carta N° 000518-2025-OAF-URDA/OSIPTEL mediante la cual se sigue el procedimiento de fiscalización del Aporte por Regulación de 2023. Revisamos los alcances de la carta, ordenamos y revisamos el histórico de documentos cursados, revisamos la matriz con el detallado de comprobantes de pago (enviados por su equipo de finanzas), trasladamos mediante correo el resultado de los hallazgos, elaboramos el proyecto de carta de respuesta donde además desarrollamos argumentos ', 'Soporte', 6, 6, 3, 'Completo', 3, 0, 1, 1, NULL, NULL, '2025-07-03 18:39:37', '2025-07-03 18:48:27'),
(36, '2025-07-03', 'Análisis y revisión', 14, 'Rafael solicitó atender la carta DMR-CE-1859-25 de CLARO por la negociación de interconexión para los servicios de telefonía y transporte conmutado local con protocolo SIP y SMS. Analizamos y ajustamos el proyecto de contrato de SMS. Validamos la información observada en el ANEXO I. Proyectamos una carta de respuesta donde desarrollamos comentarios generales sobre nuestra apreciación del proyecto de contrato de SMS, remitimos la información observada en el ANEXO I, y solicitamos ampliación del plazo para ambas negociaciones.', 'Soporte', 6, 6, 4, 'Completo', 4, 0, 1, 6, NULL, NULL, '2025-07-03 19:07:58', '2025-07-25 21:52:41'),
(37, '2025-07-07', 'Reunión', 7, 'Reunión solicitada por Julio Cieza y Giovanna Piskulich para brindar e intercambiar alcances sobre la posibilidad de aperturar en Perú un nuevo mercado mayorista para la compartición de infraestructura de telecomunicaciones para prestar servicios de conectividad, con presencia de Proveedores Importantes, en atención a experiencias de España. Se otorgaron alcances para estrategia a seguir respecto de posibles respuestas de TELEFÓNICA-INTEGRATEL.', 'Soporte', 4, 4, 1, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-07-04 17:48:04', '2025-07-08 19:43:57'),
(38, '2025-07-07', 'Reunión', 11, 'Reunión de seguimiento solicitada por Viviana Sánchez sobre análisis legal, contractual e internacional sobre la implementación de servicio de videollamadas en establecimientos penitenciarios. Se presentaron actualizaciones de la última versión del informe enviado previamente.', 'Soporte', 4, 4, 1, 'Completo', 8, 0, 1, 4, NULL, NULL, '2025-07-04 17:52:00', '2025-07-08 19:44:56'),
(39, '2025-07-04', 'Reunión', 19, 'Ximena (participó Sheyla y Joana) nos convocó a una reunión para elaborar una descripción de exención regulatoria para todos sus proyectos del SANDBOX. Revisamos el detalle del pedido y los alcances del formulario de presentación. Quedaron en enviarnos su PPT con el detalle de sus proyectos para formular nuestra descripción.', 'Soporte', 6, 6, 1, 'Completo', 3, 0, 1, 6, NULL, NULL, '2025-07-04 21:08:56', '2025-07-04 21:08:56'),
(40, '2025-07-04', 'Análisis y revisión', 22, 'Absolución de consulta respecto a la definición regulatoria y técnica de \"línea activa\" ello con la finalidad de responder a requerimiento planteado por RENTESEG. Implicó análisis del origen de una definición planteada por el OSIPTEL y su equivalencia a la definición de \"línea en servicio\" ', 'Soporte', 3, 3, 1, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-07-04 21:31:13', '2025-07-04 21:31:13'),
(41, '2025-07-03', 'Análisis y revisión', 23, 'Absolución de consultas formuladas respecto a la concesión, licencias y obligaciones regulatorias aplicables a Dolphin en relación a su renovación de concesión. Evaluación de estado de cumplimiento actual de DOLPHIN y de los riesgos en caso de denegatoria. ', 'Soporte', 3, 6, 2, 'Completo', 2, 0, 1, 5, NULL, NULL, '2025-07-04 21:35:05', '2025-07-07 16:37:26'),
(42, '2025-07-31', 'Horas audio', 22, 'Audio respecto a líneas activa solicitadas por RENTESEG (01-07-25 30 min) (SOCIOS) | Seguimiento de solicitud de numeración adicional para INTERMAX (03-07-25 30 min) (SOCIOS | JACY) | Revisión de carta que se trasladará al OSIPTEL para denunciar a TDP por el bloqueo de los mensajes A2P en la relación de interconexión con INTERMAX (10-07-25 30 min) (SOCIOS | JACY) | Audio de Kattya Vega con Gustavo Ramirez y Jacy Rojas sobre el inicio de operaciones de sus servicios portadores locales (20 min 22-7-25) | Absolución de consulta de Kattya Vega sobre fechas de publicación de tarifas en el SIRT (10 min 25-7-25) |Consulta sobre base legal de tarifa negociada solicitada por Ernesto Dávila atendida por Gustavo Ramirez (5min - 9-7-2025) | Rafael nos consultó sobre la viabilidad de atender la solicitud de BITEL vinculada a la habilitación de la numeración. Al respecto, trasladamos nuestra sugerencia de proceder con la habilitación, dentro del plazo regulado (14 días hábiles) y reiterar la atención a la solicitud de habilitación planteado por INTERMAX, además de la atención de otros compromisos pendientes. (30/07) (JANIRA) (20 min) | Absolución de consultas adicionales respecto de la tarifa a publicar para el inicio de operaciones del servicio portador local (20 min 25-07-2025/30-07-2025) (JROJAS/GUSTAVO)', 'Soporte', 3, 3, 3, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-07-04 21:49:08', '2025-07-31 21:22:47'),
(43, '2025-07-08', 'Análisis y revisión', 1, 'Elaboración Alerta Normativa diaria', 'Horas Internas', 5, 8, 3, 'Completo', 11, 0, 1, 2, NULL, NULL, '2025-07-04 22:05:25', '2025-08-01 17:34:07'),
(44, '2025-07-08', 'Análisis y revisión', 14, 'Revisión, análisis y ajustes al proyecto de contrato de interconexión de telefonía y tránsito con protocolo SIP, enviado por CLARO. Adicionalmente, se elaboró una carta complementaria.', 'Soporte', 6, 6, 4, 'Completo', 4, 0, 1, 6, NULL, NULL, '2025-07-04 22:07:00', '2025-07-31 15:20:44'),
(45, '2025-07-17', 'Horas audio', 19, 'A solicitud de Ximena: \r\n- Se envío del detalle del formulario para ingresar la solicitud del SANDBOX. (07.07.2025)\r\n- Nos contactamos con el MTC para solicitar información acerca del horario máximo de recepción de solicitudes (se envió correo de respaldo). (07.07.2025)\r\n- Absolvimos consulta adicional sobre el uso de firma electrónica en documentos para presentar ante el MTC. (07.07.2025)\r\n- Tuvimos llamada (con Ximena Guevara) para brindar alcances y solicitar ampliación de detalle de justificación normativa para proyectos de SANDBOX. (17.07.2025)', 'Soporte', 6, 6, 1, 'Completo', 3, 0, 1, 6, NULL, NULL, '2025-07-04 22:10:22', '2025-07-31 23:21:07'),
(46, '2025-07-07', 'Análisis y revisión', 7, 'Análisis y revisión de información de documentos de consulta pública de la Comisión Nacional de los Mercados y la Competencia (CNMC) sobre determinación de mercado relevante de infraestructura y proveedores importantes en España, solicitado por Giovanna Piskulich. Se realizó contraste de información con normativa aplicable y metodología de OSIPTEL para determinar proveedores importantes en Perú.', 'Soporte', 4, 4, 4, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-07-07 14:08:34', '2025-07-08 19:38:29'),
(47, '2025-07-24', 'Análisis y revisión', 6, 'Revisión de normativa correspondiente para brindar alcances ante comentario planteado por Alonso Mesones sobre la supuesta invalidez de contratos suscritos de abonados, por parte de OSIPTEL Arequipa, debido al uso en dichos acuerdos de firma no manuscrita (fotografía) del representante legal de CALA. Se brindaron recomendaciones adicionales respecto de acciones a seguir ante eventual cuestionamiento formal de dicha entidad.', 'Soporte', 4, 4, 2, 'Completo', 1, 0, 1, 4, NULL, NULL, '2025-07-07 14:27:53', '2025-07-24 19:01:36'),
(48, '2025-07-16', 'Análisis y revisión', 17, 'Revisión de proyecto de contrato y anexo, solicitado por Alonso Mesones, que CALA para identificar stoppers en la comercialización de su servicio de acceso a internet dedicado (B2B estándar). Se realizaron adecuaciones y modificaciones al contrato y anexo, en base a la revisión y análisis de la normativa regulatoria aplicable, documentos similares, así como se brindaron comentarios y recomendaciones adicionales. Por último, se elaboró carta de envío de contrato para conocimiento de OSIPTEL, conforme lo solicitado.', 'Soporte', 6, 4, 3, 'Completo', 1, 0, 1, 4, NULL, NULL, '2025-07-07 14:29:26', '2025-07-17 00:05:21'),
(49, '2025-07-09', 'Análisis y revisión', 6, 'Revisión solicitada por Alfredo Araujo para identificar el requerimiento de información contenido en la carta de OSIPTEL remitida a CALA respecto de la supuesta falta de elevación de una apelación ante el TRASU. Se brindaron alcances y recomendaciones a seguir, en función al análisis de las disposiciones e infracciones tipificadas en el TUO del Reglamento de Atención de Reclamos.', 'Soporte', 4, 4, 2, 'Completo', 1, 0, 1, 4, NULL, NULL, '2025-07-07 14:32:48', '2025-07-09 21:56:01'),
(51, '2025-07-08', 'Análisis y revisión', 20, 'Agendas Regulatorias del mes de JULIO para todos los clientes AMPARA', 'Horas Internas', 3, 8, 3, 'Completo', 11, 0, 1, 3, NULL, NULL, '2025-07-08 15:07:09', '2025-07-08 19:34:33'),
(52, '2025-07-07', 'Análisis y revisión', 19, 'Revisión y recopilación de normas del MTC para solicitar exención y/o flexibilización en propuestas de sandbox regulaorio, así como, elaboración de breve descripción por cada norma señalada, a solicitud de Sheyla Reyes. Asimismo, se enviaron comentarios y recomendaciones, así como un checklist detallado de documentos y formalidades a presentar por cada propuesta, ante consultas de Ximena Guevara vía correo electrónico.', 'Soporte', 6, 6, 4, 'Completo', 3, 0, 1, 6, NULL, NULL, '2025-07-08 15:25:17', '2025-07-08 22:07:36'),
(53, '2025-07-08', 'Análisis y revisión', 7, 'Elaboración de presentación a solicitud de Giovanna Piskulich conteniendo alcances y recomendaciones advertidas de revisión de documentos de consulta pública de España sobre determinación de mercado relevante de infraestructura y proveedores importantes.', 'Soporte', 4, 4, 2, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-07-08 16:04:23', '2025-07-08 19:46:24'),
(54, '2025-07-09', 'Análisis y revisión', 7, 'Elaboración de Informe Ejecutivo a manera de resumen solicitado por Giovanna Piskulich, en base a la revisión y análisis del Proyecto de Norma de Determinación de Proveedor Importante en el Mercado N°35.', 'Soporte', 4, 4, 3, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-07-08 16:13:11', '2025-07-10 00:22:39'),
(55, '2025-07-31', 'Horas audio', 1, 'Absolución de consulta de Jorge Ramirez por parte de Gustavo Ramirez sobre firma de órdenes de servicio para compartición de infraestructura de TDP (7.07.2025) // Envío de formato 26 por parte de Jacy Rojas, solicitado por Alfredo Araujo vía correo electrónico (8.07.2025) // Videollamada solicitada por Alonso Mesones con Gustavo y Jacy para revisión conjunta de proyecto de contrato para prestar internet dedicado (17.07.2025) // Adecuación final al proyecto de contrato para brindar acceso a internet dedicado (17.07.2025).', 'Soporte', 5, 4, 1, 'Completo', 1, 0, 1, 4, NULL, NULL, '2025-07-08 16:21:31', '2025-07-31 20:51:53'),
(56, '2025-07-08', 'Análisis y revisión', 1, 'Elaboración del boletín regulatorio correspondiente al mes de junio de 2025.', 'Horas Internas', 5, 2, 3, 'Completo', 11, 0, 1, 5, NULL, NULL, '2025-07-08 21:50:17', '2025-07-08 21:50:17'),
(57, '2025-07-08', 'Análisis y revisión', 13, 'Revisión de formalidades solicitada por Giovanna Piskulich para ingresas denuncias de uso indebido ante OSIPTEL. Se brindaron alcances en base a las consultas y correos enviados a OSIPTEL para la creación y envío de usuario y contraseña de PANGEACO para acceder al Sistema de Reporte de Denuncias por Uso Indebido – SISREDU, asimismo se envió proyecto de carta para solicitar dichas credenciales.', 'Soporte', 4, 4, 1, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-07-08 23:46:24', '2025-07-08 23:46:24'),
(58, '2025-07-10', 'Análisis y revisión', 15, 'Elaboración de presentación ejecutiva analizando los escenarios de interconexión derivados de la relación de acceso que INTERMAX (OMV) tiene con los OMR. Se realizó análisis normativo para la procedencia de establecer interconexiones directas , además del detalle de los escenarios de SMS A2P.', 'Soporte', 6, 3, 2, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-07-10 17:29:16', '2025-07-10 17:29:16'),
(59, '2025-07-10', 'Reunión', 15, 'Reunión para exponer los escenarios de interconexión derivados delas relaciones de acceso que tiene INTERMAX (OMV) con los OMR.', 'Soporte', 6, 3, 2, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-07-10 17:50:30', '2025-07-10 17:50:30'),
(60, '2025-07-09', 'Análisis y revisión', 33, 'Sheyla nos solicitó evaluar 6 consultas de su equipo de BDO vinculadas a la declaración/pago del Aporte por Regulación, Aporte al FITEL y TEC que se presenta este mes..\r\nEvaluamos los casos (incluyendo la revisión del convenio de liberación de interferencias con el MTC) y le trasladamos nuestras conclusiones por correo. ', 'Soporte', 6, 6, 1, 'Completo', 3, 0, 1, 6, NULL, NULL, '2025-07-10 20:47:19', '2025-07-25 21:55:26'),
(61, '2025-07-09', 'Reunión', 33, 'Sheyla nos convocó a una reunión para conversar acerca de las 6 consultas de su equipo de BDO vinculadas a la declaración/pago del Aporte por Regulación, Aporte al FITEL y TEC que se presenta este mes.', 'Soporte', 6, 6, 1, 'Completo', 3, 0, 1, 6, NULL, NULL, '2025-07-10 21:23:28', '2025-07-25 21:56:10'),
(62, '2025-07-11', 'Análisis y revisión', 14, 'Absolución de consulta respecto a la posibilidad de emplear los enlaces de interconexión ya implementados para el servicio fijo, con el propósito de soportar ahora el servicio móvil.', 'Soporte', 6, 3, 1, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-07-10 23:10:39', '2025-07-11 14:07:42'),
(63, '2025-07-25', 'Análisis y revisión', 14, 'Elaboración de carta dirigida al OSIPTEL a fin de trasladar comentarios sobre el proyecto de mandato de interconexión a fin de incluir el protocolo SIP  a la interconexión de CLARO con INTERMAX; se hizo lectura completa del informe donde se sustenta la emisión del mandato, se identifico los puntos para los cuales se precisarían comentarios.', 'Soporte', 6, 3, 2, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-07-10 23:13:06', '2025-07-25 19:33:36'),
(64, '2025-07-10', 'Análisis y revisión', 13, 'Análisis de respuesta extraoficial de OSIPTEL ante denuncia de uso indebido presentada por PANGEACO para identificar las posibles respuestas ante las dudas señaladas internamente por la autoridad sobre la información remitida en la denuncia. Asimismo, se brindaron recomendaciones y pasos a seguir ante el eventual requerimiento adicional de información que plantee OSIPTEL, en función de lo señalado en las Condiciones de Uso.', 'Soporte', 4, 4, 2, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-07-10 23:15:02', '2025-07-10 23:15:02'),
(65, '2025-07-11', 'Análisis y revisión', 26, 'Elaboración de comunicación que se debe trasladar al MTC para absolver 5 observaciones a la solicitud de asignación de recurso numérico para el Servicio de Telefonía Fija. ', 'Soporte', 3, 3, 3, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-07-10 23:19:33', '2025-07-12 00:46:04'),
(66, '2025-07-11', 'Análisis y revisión', 19, '- Revisión de la carta de la secretaría técnica de Solución de Controversias que solicita información vinculada a la solicitud de medida cautelar y admisión de la reclamación (además de validar los alcances de lo solicitado, se mapearon los actos procedimentales realizados).\r\n- Se revisó la información enviada por INTERMAX vinculado al requerimiento de información y el escrito enviado.\r\n- Se advirtieron observaciones y se envió un correo a Rafael detallando las observaciones y sugiriendo ajustes.', 'No Soporte', 6, 6, 3, 'Completo', 10, 0, 1, 6, NULL, NULL, '2025-07-11 14:31:31', '2025-07-11 22:59:16'),
(67, '2025-07-18', 'Análisis y revisión', 14, 'Rafael solicitó revisar los alcances de la denuncia a BITEL y plantear una respuesta alineada con la demora en la implementación de SMS. Se elaboró una carta donde se evidenció el vencimiento del plazo de implementación, el retraso del cronograma de implementación propuesto por BITEL, la falta de ajuste al cronograma propuesto, la demora en el envío del formato técnico, la falta de firma del acta por la reunión del 9 de mayo y se solicitó una reunión técnica para ajustar el cronograma.\r\nAdicionalmente, Rafael no consultó sobre la pertinencia de presentar una nueva denuncia por incumplimiento de plazos. Le trasladamos nuestra sugerencia de sujetarnos sobre la denuncia ya presentada y seguir recabando pruebas. Para esto, también se le precisó que nada impedía presentar una nueva denuncia. ', 'Soporte', 6, 6, 4, 'Completo', 4, 0, 1, 6, NULL, NULL, '2025-07-11 22:35:16', '2025-07-25 21:51:53'),
(68, '2025-07-15', 'Análisis y revisión', 11, 'Análisis y revisión solicitada por Viviana Sánchez, respecto de la norma que modifica el Reglamento del SISCRICO y el artículo 37 del Reglamento del Código de Ejecución Penal, a fin de identificar los impactos en el CIPS y actividades operativas de PRISONTEC en torno a la prestación de su servicio de telefonía pública en establecimientos penitenciarios. En función a dichos alcances se elaboró un informe ejecutivo, junto con comentarios y recomendaciones para el cliente.', 'Soporte', 4, 4, 4, 'Completo', 8, 0, 1, 4, NULL, NULL, '2025-07-11 22:57:41', '2025-07-21 22:24:14'),
(69, '2025-08-05', 'Análisis y revisión', 20, 'Elaboración de checkout para CALA. Se preparó matriz con estado actual de las obligaciones aplicables a cada servicio prestado por dicha empresa, según lo atendido por AMPARA; asimismo, se brindaron recomendaciones para el futuro.', 'Horas Internas', 3, 2, 3, 'Completo', 11, 0, 1, 2, NULL, NULL, '2025-07-11 23:02:11', '2025-08-08 20:33:30'),
(70, '2025-07-31', 'Horas audio', 1, 'Consulta de Julio Cieza con Juan Carlos Cornejo sobre caso de uso indebido en Arequipa (9.07.2025) // Consultas de Julio Cieza y Giovanna Piskulich con ambos socios sobre viabilidad de apertura de nuevo mercado de infraestructura con Proveedor Importante (10.07.2025) // Absolución de consultas adicionales de Angélica Chumpitaz atendidas vía correo electrónico por Jacy y Katy sobre el informe de renovación de concesiones (11.07.2025) // Audio y consultas por WhatsApp de Julio Cieza y Angélica Chumpitaz atendidas por Jacy Rojas sobre renovación de concesiones (14.07.2025) // Reunión solicitada por AMPARA con Giovanna Piskulich y Julio Cieza para abordar alcances estratégicos sobre el análisis de la determinación de Proveedores Importantes en mercados mayoristas (14.07.2025) // Recomendaciones vía llamada y correo a Julio Cieza por parte de Jacy Rojas sobre respuesta a OSIPTEL por caso de uso indebido (16.07.2025).', 'Soporte', 5, 4, 2, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-07-11 23:08:50', '2025-07-31 20:46:08'),
(71, '2025-07-21', 'Análisis y revisión', 11, 'Actualizar el informe sobre viabilidad para la implementación de servicio de videollamadas, solicitado por Viviana Sánchez, respecto de experiencias internacionales (benchmarking). Asimismo, se brindaron alcances adicionales respecto de la publicación de norma que modifica el artículo 37 del Reglamento del Código de Ejecución Penal.', 'Soporte', 4, 4, 3, 'Completo', 8, 0, 1, 4, NULL, NULL, '2025-07-11 23:11:30', '2025-07-30 19:06:17'),
(72, '2025-07-18', 'Reunión', 17, 'Reunión solicitada por Alonso Mesones para brindar alcances respecto de las obligaciones regulatorias aplicables al servicio de acceso a internet dedicado, arrendamiento de circutos y fibra oscura, que AMPARA desarrolló a profundidad en los informes remitidos a CALA con fecha 30.06.2025. Se brindaron recomendaciones para el tratamiento comercial de los servicios.', 'Soporte', 6, 4, 1, 'Completo', 1, 0, 1, 4, NULL, NULL, '2025-07-15 02:19:40', '2025-07-19 06:46:21'),
(73, '2025-07-24', 'Análisis y revisión', 8, 'Revisión de normativa regulatoria y de carácter general solicitado por Angélica Chumpitaz para la identificar y señalar las obligaciones aplicables a PANGEACO, respecto del tipo de servicios que brinda y títulos habilitantes que tiene para implementar su página web.', 'Soporte', 4, 4, 2, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-07-17 02:09:10', '2025-07-30 17:27:27'),
(74, '2025-07-24', 'Análisis y revisión', 7, 'Elaboración de informe solicitado por Julio Cieza respecto de la viabilidad para implementar un nuevo mercado mayorista de infraestructura física de telecomunicaciones. Se realizó análisis y revisión de normativa aplicable, así como de documentos asociados para plantear los principales obstáculos que dicha propuesta trae consigo: i) necesidad de modificar normativa y ii) demostrar la presencia de Proveedores Importantes en el mismo.', 'Soporte', 4, 4, 4, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-07-17 02:13:47', '2025-07-24 18:57:47'),
(75, '2025-07-25', 'Análisis y revisión', 15, 'Jaime nos solicitó atender la carta C. 000298-2025-DPRC/OSIPTEL referida a los comentarios de Integratel al proyecto de mandato de acceso. Revisión del proyecto de mandato de acceso. Análisis y comentarios a la referida carta.', 'Soporte', 6, 6, 4, 'Completo', 2, 0, 1, 6, NULL, NULL, '2025-07-17 18:11:08', '2025-07-25 23:43:23'),
(76, '2025-08-18', 'Análisis y revisión', 7, 'Elaboración de informe con análisis solicitado por Julio Cieza respecto de escenarios complementarios que el cliente planteó ante la eventual resolución de su OBC con INTEGRATEL: i) viabilidad regulatoria para continuar utilizando infraestructura de INTEGRATEL bajo Ley General de Compartición y ii) Denunciar a INTEGRATEL ante Cuerpo Colegiado de OSIPTEL por abuso de posición de dominio en la modalidad de negativa injustificada para contratar. Se incluyeron alcances, detalle de riesgos advertidos y algunas recomendaciones.', 'Soporte', 4, 4, 5, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-07-19 06:42:50', '2025-09-01 00:19:20'),
(77, '2025-07-21', 'Análisis y revisión', 24, 'Análisis normativo y regulatorio de aplicación del pago anual del canon frente a la instalación y operación de VSAT operadas por PUNTO DE ACCESO u otros proveedores, Así como análisis de la no aplicación de dicho pago al uso de bandas libres: \r\n- Revisión de reglamento General de la ley\r\n-Revisión de antecedentes de otras empresas respecto al pago del canon\r\n\r\nAdemás, absolución de consultas respecto a responsabilidad económica del proveedor del servicio (HUGHES) frente al pago del canon anual, para lo cual se analizó el alcance de los servicios que están sujetos a dicho pago.', 'Soporte', 3, 3, 3, 'Completo', 9, 0, 1, 3, NULL, NULL, '2025-07-21 13:25:31', '2025-08-01 18:52:25'),
(78, '2025-07-21', 'Análisis y revisión', 14, 'Elaboración de comunicación para brindar respuesta a la solicitud de modificación de contrato de interconexión entre BITEL e INTERMAX, además de análisis y estrategia frente a la modificación de la clausula de mecanismos Anti-spam sustentando posición en pronunciamientos previos del OSIPTEL. Ademas de comentarios a las referencias de los principios de igualdad de acceso, predictibilidad y temporalidad', 'Soporte', 6, 3, 4, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-07-21 13:29:30', '2025-07-25 19:19:16'),
(79, '2025-07-22', 'Análisis y revisión', 12, 'Análisis y revisión de normativa aplicable para brindar alcances y estrategias a seguir solicitado por Kattya Vega para acreditar inicio de operaciones de INTERMAX respecto de su servicio portador local en su modalidad conmutado y no conmutado. Para el conmutado, se revisó y adecuó modelo de contrato y tarifa correspondientes, así como se brindó recomendaciones para su envío a OSIPTEL. Para el no conmutado, se presentaron los esquemas comerciales advertidos para la contratación de internet dedicado, así como las disposiciones para el arrendamiento de circuitos; para revisión y evaluación del cliente considerando la fecha máxima de inicio de operaciones.', 'Soporte', 4, 3, 4, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-07-21 13:31:19', '2025-07-25 19:22:20'),
(80, '2025-07-25', 'Análisis y revisión', 14, 'Elaboración de la cuarta adenda entre ENTEL con INTERMAX a fin de subsanar observaciones que plantean incluir la red del servicio portador de larga distancia internacional de INTERMAX y los escenarios de liquidación de tráfico de los servicios de cobro revertido (0800) y pago compartido (0801); además de prescindir de los escenarios de portador de larga distancia nacional y transporte conmutado prestados por ENTEL.', 'Soporte', 6, 3, 2, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-07-21 13:47:22', '2025-07-31 21:01:08'),
(82, '2025-07-18', 'Reunión', 23, 'Reunión respecto al inicio de operaciones del serviico portador local conmutado y no conmutado, se absolvieron consultas respecto a publicación de tarifa, contratos y obligaciones regulatorias.', 'Soporte', 3, 3, 1, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-07-21 14:00:25', '2025-07-21 14:00:25'),
(83, '2025-07-18', 'Análisis y revisión', 19, 'Análisis y revisión de normativa del MTC solicitado por Ximena Guevara para señalar flexibilizaciones y/o exenciones que se tomarán como justificación normativa para cada proyecto de sandbox propuesto por IPT. Se elaboró cuadro indicando las referencias normativas correspondientes, de acuerdo con la información descriptiva y técnica enviada por el cliente por cada propuesta.', 'Soporte', 6, 6, 4, 'Completo', 3, 0, 1, 6, NULL, NULL, '2025-07-21 14:08:01', '2025-07-21 15:41:29'),
(84, '2025-07-21', 'Reunión', 14, 'Reunión de coordinación con el equipo de Rafael para definir la estrategia para la reunión técnica con BITEL (ajuste de cronograma de implementación de SMS). Se envió la propuesta de cronograma (FIBERMAX) por correo.', 'Soporte', 6, 6, 1, 'Completo', 4, 0, 1, 6, NULL, NULL, '2025-07-21 14:30:31', '2025-07-22 15:39:14'),
(85, '2025-07-18', 'Análisis y revisión', 17, 'Elaboración y envío al cliente de presentación conteniendo los alcances relevantes de las obligaciones aplicables a los servicios de acceso a internet dedicado, arrendamiento de circuitos y fibra oscura.', 'Soporte', 6, 4, 2, 'Completo', 1, 0, 1, 4, NULL, NULL, '2025-07-21 15:23:40', '2025-07-21 15:23:40'),
(87, '2025-07-22', 'Reunión', 14, 'Acompañamiento a la reunión técnica con BITEL para el ajuste de cronograma de implementación de SMS. Se envió el cronograma ajustado y acordado en reunión. Se revisó y ajustó el acta.', 'Soporte', 6, 6, 1, 'Completo', 4, 0, 1, 6, NULL, NULL, '2025-07-22 15:38:29', '2025-07-31 21:55:15'),
(88, '2025-07-24', 'Análisis y revisión', 1, 'Revisión y análisis de proyecto normativo sobre inaplicación de normativa regulatoria durante la contratación con abonados corporativos para brindar comentarios a los hallazgos advertidos y remitidos por Angélica Chumpitaz y que podrían afectar a PANGEACO. Se brindaron recomendaciones en archivo remitido.', 'Soporte', 5, 4, 2, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-07-24 03:25:18', '2025-07-24 18:59:26'),
(89, '2025-07-30', 'Análisis y revisión', 3, 'Elaboración de matriz normativa solicitado por Pedro Castro conteniendo el detalle de obligaciones legales aplicables al encargado del tratamiento de datos personales, en cumplimiento de la Ley N°29733 (Ley de Protección de Datos Personales) y su reglamento (D.S. N°016-2024-JUS). Se realizó reunión previa al respecto con participación de Mapi Castañeda y Pedro Castro con fecha 22.07.2025.', 'Soporte', 5, 4, 3, 'Completo', 8, 0, 1, 4, NULL, NULL, '2025-07-24 03:29:08', '2025-07-31 21:04:39'),
(90, '2025-07-24', 'Reunión', 19, 'Reunión con Sheyla, Joana y Ximena para comentarnos sobre los resultados de su reunión con el MTC por el tema del SANDBOX REGUALTORIO. Nos solicitaron elaborar un documento con más detalles de las exoneraciones regulatorias para los 10 proyectos presentados.', 'Soporte', 6, 6, 1, 'Completo', 3, 0, 1, 6, NULL, NULL, '2025-07-24 16:57:02', '2025-07-24 16:57:02'),
(91, '2025-07-22', 'Análisis y revisión', 14, 'Exposición temática: elaboración de presentación, elaboración de examen y presentación del tema de INTERCONEXIÓN.', 'Horas Internas', 6, 2, 3, 'Completo', 11, 0, 1, 3, NULL, NULL, '2025-07-25 19:25:35', '2025-07-25 19:25:35'),
(92, '2025-07-31', 'Análisis y revisión', 20, 'Se elaboró una matriz con un listado de obligaciones de CALA para enviárselo a su salida. Se han añadido comentarios/sugerencias de AMPARA.', 'Horas Internas', 3, 2, 1, 'Completo', 11, 0, 1, 6, NULL, NULL, '2025-07-31 15:11:37', '2025-07-31 15:11:37'),
(93, '2025-07-31', 'Análisis y revisión', 14, 'Ernesto nos solicitó validar la información enviada por BITEL respecto a la implementación de la OS de telefonía con protocolo SIP. Trasladamos por correo nuestra posición sobre la propuesta económica de BITEL por correo electrónico. Rafael nos solicitó elaborar y enviarle una carta recogiendo nuestra posición. Enviamos la carta con dichas especificaciones. Posteriormente, adecuamos la carta incluyendo un pronunciamiento adicional sobre la OS enviada por BITEL. Por correo comunicamos los detalles de estas adecuaciones.', 'Soporte', 6, 6, 3, 'Completo', 4, 0, 1, 6, NULL, NULL, '2025-07-31 15:13:13', '2025-08-01 18:36:17'),
(94, '2025-08-08', 'Análisis y revisión', 14, 'Elaboración de informe ejecutivo que contempla el análisis de la Ley 32323 (que modifica la Ley del consumidor) y del proyecto normativo que para la lucha contra llamadas y SMS ilicitos; ello con la finalidad de evaluar su impacto en el servicio de SMS A2P con numeración alfanumérica provista por INTERMAX. Adicionalmente se incluyo la vinculación de la normativa citada con la solicitud de modificación de mandato trasladada por BITEL, centrando el cambio en la clausula de Mecanismos Anti-spam.', 'Soporte', 6, 3, 4, 'Anulado', 5, 0, 0, 0, NULL, NULL, '2025-07-31 15:16:09', '2025-08-11 17:08:46'),
(95, '2025-07-31', 'Análisis y revisión', 12, 'Elaboración de esquema tarifario solicitado por Kattya Vega de cara al inicio de operaciones del servicio portador local no conmutado. Se revisaron esquemas tarifarios similares utilizados por otras empresas operadoras respecto del servicio de arrendamiento de circuitos.', 'Soporte', 4, 3, 2, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-07-31 15:17:26', '2025-07-31 15:17:26'),
(96, '2025-07-31', 'Análisis y revisión', 19, 'A solicitud de Rafael, seguimiento al OSIPTEL para la emisión de la resolución que se pronuncia sobre la MC (24.07)\r\nRevisión de la resolución y mapear los plazos para considerarla ejecución de la MC (30.07)\r\nCorreos de respuesta a Rafael y Kattya sobre las consultas vinculadas a la ejecución de la MC (31.07)', 'No Soporte', 6, 6, 2, 'Completo', 10, 0, 1, 6, NULL, NULL, '2025-07-31 22:29:39', '2025-07-31 22:29:39'),
(97, '2025-07-31', 'Horas audio', 12, 'Absolución de consultas adicionales de Javier Sanchez sobre tarifas de comercializadores por parte de Gustavo Ramirez para lo cual se realizaron consultas al OSIPTEL (04.07). Resolución de consultas y seguimiento a temas varios.', 'Soporte', 4, 6, 1, 'Completo', 2, 0, 1, 2, NULL, NULL, '2025-07-31 22:59:43', '2025-08-01 17:49:02'),
(98, '2025-07-30', 'Horas audio', 14, 'Consulta de Ernesto sobre el incumplimiento de BITEL respecto del nuevo cronograma de implementación de SMS. Al respecto, trasladamos nuestra sugerencia de ser persistentes con el seguimiento y propiciar el envío de comunicaciones que  permitan dejar constancia que FIBERMAX estuvo actuando con diligencia para exigir su cumplimiento. Se está a la espera de una respuesta de BITEL para elaborar una carta complementaria a la denuncia ya planteada. (30/07) (JANIRA). Seguimiento, control y absolución de consultas varias a través de llamadas y mensajes.', 'Soporte', 6, 6, 1, 'Completo', 4, 0, 1, 2, NULL, NULL, '2025-07-31 23:19:21', '2025-08-01 17:45:51'),
(99, '2025-08-01', 'Análisis y revisión', 25, 'Agendas Regulatorias del mes de AGOSTO para todos los clientes AMPARA', 'Horas Internas', 3, 2, 3, 'Completo', 11, 0, 1, 3, NULL, NULL, '2025-08-01 17:09:00', '2025-08-01 17:09:00'),
(100, '2025-07-31', 'Horas audio', 25, 'Seguimiento de actividades a seguir a fin de iniciar las operaciones del servicio de Portador Local conmutado; para lo cual se elaboró un correo trasladando mapa detallado de obligaciones, asi como cronograma con los plazos establecidos para cada actividad (15-07-25) | Absolución de consulta respecto al reporte del formato 25 SIGEP y precisión de formato a reportar al SIGIEP (25-07-25) | Respuesta a consulta sobre implicancia en pagos regulatorios  si es que el pago de Urbi a PAPSAC se realiza al término de la contraprestación (25-07-25)', 'Soporte', 3, 3, 1, 'Completo', 9, 0, 1, 3, NULL, NULL, '2025-08-01 18:40:51', '2025-08-01 18:40:51'),
(101, '2025-08-31', 'Horas audio', 14, 'LLamada de coordinación para absolver consulta de Ernesto respecto a RENTESEG (6-8-25) (JACY) (5 min)| LLamada de coordinación para absolver consulta de Ernesto respecto a los comentarios del proyecto de mandato de acceso con ENTEL (7-8-25) (JACY) (5 min) | Elaboración de correo a fin de brindar recomendaciones frente a la implementación de la conexión con RENTESEG (6-8-25) (JACY/SOCIOS) (15 min) | Elaboración de carta para brindar respuesta a BITEL respecto a sus comentarios frente a la solicitud de la clausula Antispam, adicionalmente se solicitó ampliar el plazo de negociación a fin de poder llevar a cabo una reunión (7-8-25) (SOCIOS/JACY) (30 min) | Llamada con Ernesto a fin de absolver consultas respecto a correo de BITEL en la cual se plantea dejar precedente de la no implementación del mandato de Acceso (15-8-25) (JACY) (15 min) | estrategia a seguir ante la negatoria de OSIPTEL de ampliar el plazo para remitir la 3era adenda con ENTEL y la culminación del procedimiento. (25-8-25) (SOCIOS/JACY) (20 min) | Correo precisando estrategia frente a la reunión con BITEL por la modificación de la clausula Antispam (26-8-25) (JACY) (20 min)  | Envío de modelos de contratos con clientes, elaborados por AMPARA solicitado por Lizzet (4-9-25) (GUSTAVO) (10 min)', 'Soporte', 6, 3, 2, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-08-04 13:44:13', '2025-09-01 14:48:47'),
(102, '2025-08-27', 'Análisis y revisión', 14, 'Elaboración de cuarto addendum para solicitar la interconexión del servicio movil de INTERMAX (como OMV) con los servicios de Telefónica. Se incorporo cambios en los anexos asociados al servicio de telefonía fija y a los anexo asociados al servicio de SMS', 'Soporte', 6, 3, 4, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-08-04 13:46:16', '2025-08-26 20:58:48'),
(103, '2025-08-07', 'Reunión', 5, 'Reunión para presentar análisis de la Ley Antispam y Proyecto normativo a fin de establecer su impacto en los SMS A2P. Adicionalmente se presentaron antecedentes de la denuncia del Secreto de las Telecomunicaciones y posibles caminos a seguir', 'Soporte', 5, 3, 3, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-08-04 13:48:07', '2025-08-08 21:26:10'),
(104, '2025-08-05', 'Análisis y revisión', 15, 'Elaboración de comentarios a la carta trasladada por ENTEL con sus descargo respecto al proyecto de mandato de acceso. Se realizó una lectura integral de los descargos para su posterior análisis y sustento que refuercen nuestra posición frente a la solicitud de mandato de acceso', 'Soporte', 6, 3, 4, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-08-04 13:51:55', '2025-08-05 21:40:56'),
(105, '2025-08-04', 'Análisis y revisión', 19, 'A solicitud de Sheyla, actualizamos la matriz que contiene el detalle de la flexibilización normativa a ser considerada para efectos del SANDBOX regulatorio. Se agregó la obtención del registro de valor añadido (conmutación de datos por paquetes), cumplimiento de los indicadores de calidad (continuidad del servicio) como OIMR, homologación e internamiento de equipos y aprobación del MTC de arrendamiento de bandas. Adicionalmente, se mandó un correo con un resumen de las normas y algunas precisiones adicionales.\r\n', 'Soporte', 6, 6, 4, 'Completo', 3, 0, 1, 2, NULL, NULL, '2025-08-08 20:29:43', '2025-08-08 22:01:13'),
(106, '2025-08-07', 'Análisis y revisión', 14, 'Elaboración de carta para brindar respuesta a BITEL respecto a sus comentarios frente a la solicitud de la clausula Antispam, adicionalmente se solicitó ampliar el plazo de negociación a fin de poder llevar a cabo una reunión.', 'Soporte', 6, 3, 1, 'Anulado', 5, 0, 0, 0, NULL, NULL, '2025-08-08 21:23:16', '2025-08-11 17:11:25'),
(107, '2025-08-07', 'Análisis y revisión', 19, 'Se recabó el histórico de comunicaciones entre INTERMAX-TELEFÓNICA. Se elaboró una matriz ordenando y describiendo brevemente cada comunicación. Se intercambiaron comunicaciones con INTERMAX para validar que la información esté completa.', 'No Soporte', 6, 6, 4, 'Completo', 10, 0, 1, 6, NULL, NULL, '2025-08-08 21:25:30', '2025-08-08 21:25:30'),
(108, '2025-08-08', 'Análisis y revisión', 26, 'Elaboración de PPT para la reunión donde se revisara análisis de la Ley Antispam y Proyecto normativo a fin de establecer su impacto en los SMS A2P. Adicionalmente la denuncia del Secreto de las Telecomunicaciones y posibles caminos a seguir. Lo cual partio de la elaboración de informe ejecutivo que contempla el análisis de la Ley 32323 (que modifica la Ley del consumidor) y del proyecto normativo que para la lucha contra llamadas y SMS ilicitos; ello con la finalidad de evaluar su impacto en el servicio de SMS A2P con numeración alfanumérica provista por INTERMAX. Adicionalmente se incluyo la vinculación de la normativa citada con la solicitud de modificación de mandato trasladada por BITEL, centrando el cambio en la clausula de Mecanismos Anti-spam.', 'Soporte', 3, 3, 5, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-08-08 21:32:15', '2025-08-11 17:10:52');
INSERT INTO `liquidacion` (`idliquidacion`, `fecha`, `asunto`, `tema`, `motivo`, `tipohora`, `acargode`, `lider`, `cantidahoras`, `estado`, `idcontratocli`, `idpresupuesto`, `activo`, `editor`, `enlace_onedrive`, `fecha_completo`, `registrado`, `modificado`) VALUES
(109, '2025-08-07', 'Análisis y revisión', 19, 'Análisis y revisión de proyecto de norma que modifica Reglamento de Infracciones y Sanciones de OSIPTEL. Se elaboró correo recordatorio para todos los clientes sobre la elaboración de comentarios al proyecto considerando el plazo máximo de presentación indicado en la resolución.', 'Horas Internas', 6, 2, 1, 'Completo', 11, 0, 1, 2, NULL, NULL, '2025-08-08 21:43:26', '2025-08-08 21:43:26'),
(110, '2025-08-11', 'Análisis y revisión', 25, 'A solicitud de Kazhia, atendimos su consulta relacionada con la aplicación del formato F006-CIT-1A (infraestructura). Sugerimos enviar un correo aclaratorio al MTC para que considere cumplida la obligación de presentación de dicho formato y revierta su eliminación en el SIGIEP. Para esto, además, nos comunicamos previamente con el MTC. Adicionalmente, se envió un recordatorio sobre los formatos próximos a vencer (19.08)', 'Soporte', 3, 3, 1, 'Completo', 9, 0, 1, 6, NULL, NULL, '2025-08-11 21:45:49', '2025-08-11 21:45:49'),
(111, '2025-08-12', 'Análisis y revisión', 14, 'Análisis y elaboración de carta con comentarios a los descargos realizados por CLARO al proyecto de mandato de interconexión para la incorporación del protocolo SIP. Se analizo cada uno de los comentarios trasladados por CLA y se formulo un sustento regulatorio que sustente nuestra posición frente a ello.', 'Soporte', 6, 3, 3, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-08-12 21:33:54', '2025-08-12 21:33:54'),
(113, '2025-08-12', 'Análisis y revisión', 1, 'A solicitud de los socios, se recopiló información vinculada a INTERMAX-BITEL: Medida correctiva - Secreto de la Telecomunicaciones - Contratos/Mandatos INTERMAX-BITEL', 'Horas Internas', 5, 2, 2, 'Completo', 11, 0, 1, 2, NULL, NULL, '2025-08-12 22:31:08', '2025-08-15 21:27:21'),
(114, '2025-08-13', 'Análisis y revisión', 14, 'Análisis y revisión de carta que se debe trasladar a BITEL  fin de sustentar la posibilidad de coexistencia de implementación de protocolo SIP y SS7. Se adicionaron sustentos respecto a la neutralidad tecnológica y lo establecido explícitamente en el mandato de interconexión.', 'Soporte', 3, 3, 1, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-08-13 16:54:27', '2025-08-13 16:54:27'),
(115, '2025-08-14', 'Análisis y revisión', 1, 'Se envió un correo informativo a todos los clientes sobre la consulta temprana respecto a la necesidad de adecuar la Norma de Requerimientos de Información Periódica (NRIP) (30min). \r\n', 'Horas Internas', 6, 2, 1, 'Completo', 11, 0, 1, 6, NULL, NULL, '2025-08-14 17:30:50', '2025-08-14 17:30:50'),
(116, '2025-08-15', 'Reunión', 25, 'Reunión con Kazhia donde absolvimos consultas vinculadas a los formatos del SIGIEP y SIGEP (30min)', 'Soporte', 6, 6, 1, 'Completo', 9, 0, 1, 2, NULL, NULL, '2025-08-15 22:45:18', '2025-08-16 06:31:12'),
(117, '2025-08-15', 'Análisis y revisión', 14, 'Elaboración de solicitud de emisión de mandatos para el servicio de telefonía con los servicios de CLARO. Se analizaron los puntos discrepantes y antecedentes a fin de precisar de manera clara dentro de la solicitud realizada. Adicionalmente se elaboraron los anexos correspondientes de acuerdo a la norma de emisión de mandatos', 'Soporte', 3, 3, 2, 'Completo', 4, 0, 1, 3, NULL, NULL, '2025-08-15 23:57:31', '2025-08-25 14:54:39'),
(118, '2025-08-15', 'Reunión', 15, 'Reunión para evaluar comunicación de BITEL en la que se pretende dejar precedente la no implementación del mandato de acceso', 'Soporte', 3, 3, 1, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-08-16 00:05:19', '2025-08-16 00:07:21'),
(119, '2025-08-15', 'Reunión', 7, 'Reunión solicitada por Julio Cieza para presentar alcances sobre estrategias a seguir frente a la resolución de la OBC con INTEGRATEL. Se presentaron nuevos entregables y estrategias a seguir (denuncia por barreras burocráticas).', 'Soporte', 4, 4, 1, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-08-16 01:24:51', '2025-09-01 23:53:44'),
(120, '2025-08-26', 'Análisis y revisión', 14, 'Análisis y elaboración de comentarios al Proyecto de Norma sobre Marco Normativo de mensajes y llamadas con fines ilícitos y ANTISPAM, a fin de presentarlos al MTC', 'Soporte', 3, 3, 3, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-08-18 21:55:53', '2025-08-28 15:18:41'),
(121, '2025-08-20', 'Reunión', 3, 'Reunión solicitada por Ana Paula Morales para solicitar a AMPARA un nuevo entregable sobre ejecución de obligaciones como Encargado del Tratamiento de Datos Personales. Asimismo, se trató el seguimiento de otros temas que aún se mantienen en discusión con el cliente.', 'Soporte', 6, 4, 1, 'Completo', 8, 0, 1, 4, NULL, NULL, '2025-08-18 22:01:43', '2025-09-01 23:50:16'),
(122, '2025-08-18', 'Análisis y revisión', 7, 'Revisión y análisis de normativa regulatoria y de carácter general aplicables para absolver pliego de consultas remitido por Kazhia Fernandez, sobre la tramitación de permisos municipales (FUIIT) y autorización ambiental (FTA) para instalar infraestructura de telecomunicacione, medición de parámetros RNI, página web, entre otros.', 'Soporte', 4, 6, 4, 'Completo', 9, 0, 1, 6, NULL, NULL, '2025-08-19 20:12:00', '2025-08-19 20:12:00'),
(123, '2025-08-21', 'Análisis y revisión', 33, 'A solicitud de Sheyla, se revisó una PPT con motivo de la próxima la reunión con el MTC respecto al impacto de las obligaciones económicas en los OIMR. Se realizaron algunos ajustes en el orden de las láminas; se incluyó un espacio para la historia de MAYU; se revisó y analizó el Expediente 0005-2023-OAF-URDA-FIS/OSIPTEL y se incluyó la posición del OSIPTEL; finalmente, se agregaron algunos comentarios y una conclusión de cierre.', 'Soporte', 6, 6, 2, 'Completo', 3, 0, 1, 6, NULL, NULL, '2025-08-19 20:19:54', '2025-08-22 14:13:22'),
(124, '2025-08-26', 'Análisis y revisión', 7, 'Revisión y análisis normativo para elaborar informe solicitado por Julio Cieza sobre posibilidad de denunciar a OSIPTEL ante INDECOPI por haber emitido una barrera burocrática en la resolución que determinó proveedores importantes en Mercado N°25 y próximamente en el Mercado N°35. Se incluyó: análisis en función a la metodología de evaluación aplicada por INDECOPI (ilegalidad y razonabilidad); nuestros comentarios ante la supuesta falta de Análisis de Impacto Regulatorio, por parte de OSIPTEL y algunas recomendaciones a seguir, en base al contrato OBC suscrito con INTEGRATEL. ', 'Soporte', 4, 4, 5, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-08-21 19:15:59', '2025-08-30 06:40:55'),
(125, '2025-08-20', 'Análisis y revisión', 17, 'Búsqueda de pronunciamientos de OSIPTEL sobre principio de no discriminación solicitado por Giovana Piskulich. Se remitió informe que contiene comentario y análisis realizado previamente por AMPARA sobre negativa injustificada para contratar y principio de no discriminación.', 'Soporte', 4, 4, 1, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-08-21 19:31:11', '2025-08-29 01:36:53'),
(126, '2025-09-08', 'Análisis y revisión', 14, 'Elaboración de Recurso de Reconsideración a fin de trasladar comentarios al Mandato de interconexión entre INTEGRATEL y FIBERMAX aprobado por OSIPTEL, mediante el cual se ha relacionado a los SMS alfanuméricos con los servicios especiales facultativos.', 'Soporte', 3, 3, 12, 'Completo', 4, 0, 1, 3, NULL, NULL, '2025-08-21 21:52:20', '2025-09-08 17:41:21'),
(127, '2025-08-21', 'Reunión', 33, 'Reunión con Sheyla, Rosa y Hector para definir la estrategia a seguir en la reunión con el MTC respecto al impacto de las obligaciones económicas en los OIMR. Además, se expuso la propuesta de cambios a la PPT enviada.', 'Soporte', 6, 6, 1, 'Completo', 3, 0, 1, 6, NULL, NULL, '2025-08-22 14:00:09', '2025-08-22 14:05:08'),
(129, '2025-09-15', 'Análisis y revisión', 5, 'Elaboración de una nueva denuncia contra BITEL por vulnerar el secreto de las telecomunicaciones de los usuarios. Se sustento la competencia del MTC respecto a supervisar el cumplimiento del secreto, se fundamento argumentos nuevos tomando como referencia la MC impuesta a BITEL.', 'Soporte', 6, 3, 5, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-08-22 17:38:56', '2025-09-18 14:47:23'),
(130, '2025-08-27', 'Análisis y revisión', 14, 'Análisis del Proyecto de Norma sobre Marco Normativo de mensajes y llamadas con fines ilícitos y ANTISPAM para presentación de comentarios al MTC ', 'Soporte', 3, 3, 2, 'Anulado', 5, 0, 0, 0, NULL, NULL, '2025-08-25 13:33:40', '2025-08-25 13:37:48'),
(131, '2025-10-31', 'Reunión', 14, 'Reunión con BITEL respecto a la Modificación de Mandato de interconexión respecto de la clausula de Mecanismos Antispam (SE REPROGRAMARÁ)', 'Soporte', 3, 3, 1, 'Anulado', 5, 0, 0, 0, NULL, NULL, '2025-08-25 13:35:27', '2025-10-31 16:45:02'),
(132, '2025-08-25', 'Análisis y revisión', 14, 'estrategia a seguir ante la negatoria de OSIPTEL de ampliar el plazo para remitir la 3era adenda con ENTEL y la culminación del procedimiento.', 'Soporte', 3, 3, 1, 'Anulado', 5, 0, 0, 0, NULL, NULL, '2025-08-25 13:36:34', '2025-08-25 15:14:52'),
(133, '2025-08-29', 'Análisis y revisión', 1, 'Elaboración de respuesta al traslado de recurso de apelación presentado por CLARO contra la Medida Cautelar ', 'No Soporte', 6, 6, 15, 'Completo', 10, 0, 1, 3, NULL, NULL, '2025-08-25 14:05:54', '2025-08-29 14:07:10'),
(134, '2025-08-27', 'Análisis y revisión', 1, 'Elaboración de reclamación y medida Cautelar a Telefónica por interrupción de la interconexión de SMS', 'No Soporte', 6, 6, 20, 'Completo', 10, 0, 1, 3, NULL, NULL, '2025-08-25 14:07:20', '2025-08-29 14:06:40'),
(135, '2025-09-10', 'Análisis y revisión', 3, 'Análisis y revisión de alcances para el cumplimiento de obligaciones aplicables a PRISONTEC en calidad de Encargado del Banco de Datos Personales de grabaciones de voz de los internos, contenidas en matriz elaborada por AMPARA, solicitado por Pedro Castro. Se incluyeron comentarios respecto de obligaciones aplicables a PRISONTEC respecto de otros bancos de datos personales.', 'Soporte', 6, 4, 2, 'Completo', 8, 0, 1, 4, NULL, NULL, '2025-08-25 14:16:00', '2025-09-11 21:53:33'),
(136, '2025-08-31', 'Análisis y revisión', 7, 'Revisión de contrato OBC suscrito entre PANGEACO e INTEGRATEL, así como documentos asociados, para solicitar el acceso y uso de sus ductos, conductos, poliductos y cámaras, para elaborar flujo didáctico solicitado por Julio Cieza sobre el proceso de contratación de dicha infraestructura. Se incluyeron alcances sobre cada paso del procedimiento.', 'Soporte', 4, 4, 3, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-08-25 14:19:45', '2025-08-31 23:50:55'),
(137, '2025-08-15', 'Análisis y revisión', 14, 'Elaboración de solicitud de emisión de mandatos para el servicio de SMS con CLARO. Se analizaron los puntos discrepantes y antecedentes a fin de precisar de manera clara dentro de la solicitud realizada. Adicionalmente se elaboraron los anexos correspondientes de acuerdo a la norma de emisión de mandatos', 'Soporte', 3, 3, 2, 'Completo', 4, 0, 1, 3, NULL, NULL, '2025-08-25 14:58:34', '2025-08-25 14:58:34'),
(138, '2025-08-25', 'Análisis y revisión', 1, 'Elaboración de carta que se debe enviar al OSIPTEL a fin de que se nos notifique el informe de fiscalización del MTC que fue citado en la emisión de mandato entre FIBERMAX e INTEGRATEL', 'Soporte', 6, 3, 1, 'Completo', 4, 0, 1, 3, NULL, NULL, '2025-08-25 15:07:39', '2025-08-26 20:55:43'),
(139, '2025-08-29', 'Análisis y revisión', 17, 'Elaboración de informe conteniendo análisis solicitado por Giovana Piskulich en torno a la interpretación de las obligaciones contenidas en la Cláusula 5.01.9 del Contrato WSA para determinar posibles acciones que le permitan impedir a INTEGRATEL solicitar la adecuación de sus precios, tomando como referencia a la contratación de servicios de conectividad con otros operadores utilizando precios más bajos.', 'Soporte', 4, 4, 4, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-08-29 00:52:04', '2025-08-30 06:32:18'),
(140, '2025-08-27', 'Análisis y revisión', 34, 'Elaboración de presentación didáctica (ppt) respecto del tema “Certificación ambiental para la implementación de infraestructura de telecomunicaciones”. Exposición de dicho tema ante el equipo AMPARA.', 'Horas Internas', 4, 2, 3, 'Completo', 11, 0, 1, 4, NULL, NULL, '2025-08-29 01:07:40', '2025-08-29 01:07:40'),
(141, '2025-08-29', 'Reunión', 20, 'Reunión con Sheyla, Joana y su equipo comercial para definir la categoría del servicio denominado \"de última milla\" para su cliente WIN - Austral. Se concluyó que además de un servicio de última milla (mufa-ODF), se incluía un servicio de transporte (nacional).', 'Soporte', 3, 6, 1, 'Completo', 3, 0, 1, 6, NULL, NULL, '2025-08-29 14:44:48', '2025-08-29 14:44:48'),
(142, '2025-08-29', 'Análisis y revisión', 1, 'Elaboración de escritos de designación de representantes para CLARO e INTEGRATEL (30 MIN)', 'No Soporte', 6, 6, 1, 'Completo', 10, 0, 1, 6, NULL, NULL, '2025-08-29 16:54:50', '2025-08-29 16:54:50'),
(143, '2025-08-29', 'Análisis y revisión', 14, 'Reunión para establecer estrategia frente a la implementación del protocolo SIP con BITEL, ademas se revisó los comentarios al proyecto de la Norma Antispam', 'Soporte', 3, 3, 2, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-08-29 18:02:06', '2025-08-29 18:02:06'),
(144, '2025-08-29', 'Análisis y revisión', 1, 'Revisión de El Peruano, agendas del CD del OSIPTEL y otros pronunciamientos relevantes para el envío de la alerta normativa (en total, 1h y 30min en todo el mes de agosto).', 'Horas Internas', 6, 2, 2, 'Completo', 11, 0, 1, 6, NULL, NULL, '2025-08-29 21:24:40', '2025-08-29 21:24:40'),
(145, '2025-09-01', 'Análisis y revisión', 17, 'Búsqueda en base de datos de entidades públicas (PRONATEL y SEACE) para recopilar contratos y adendas suscritos entre GILAT PERÚ y PRONATEL sobre proyectos regionales para la implementación de redes de telecomunicaciones de banda ancha, solicitado por Julio Cieza. Asimismo, se ingresaron solicitudes de acceso a la información pública respecto de los acuerdos firmados recientemente entre ambas partes y que no están disponibles en internet.', 'Soporte', 4, 4, 2, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-08-31 23:48:02', '2025-09-01 23:43:20'),
(146, '2025-09-04', 'Análisis y revisión', 7, 'Revisión de contrato OBC suscrito entre PANGEACO e INTEGRATEL, así como documentos asociados, para solicitar el acceso y uso de sus racks y provisión de energía, a fin de elaborar flujo didáctico solicitado por Julio Cieza sobre el proceso de contratación de dicha infraestructura. Se incluyeron alcances sobre cada paso del procedimiento.', 'Soporte', 4, 4, 3, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-09-01 00:04:56', '2025-09-04 20:23:04'),
(147, '2025-09-17', 'Análisis y revisión', 11, 'Análisis y revisión de alcances del CIPS, disposiciones regulatorias de OSIPTEL, así como documentación sobre proyectos regionales, para elaborar el protocolo para medir disponibilidad de bloqueadores instalados en establecimientos penitenciarios, solicitado por Pedro Castro. Se incluyeron casuísticas, definiciones y otros detalles solicitados por el cliente.', 'Soporte', 4, 4, 7, 'Completo', 8, 0, 1, 4, NULL, NULL, '2025-09-01 00:09:35', '2025-09-18 01:17:17'),
(148, '2025-10-22', 'Análisis y revisión', 14, 'Revisión de la adenda que subsana observaciones de contrato de interconexión entre FIBERMAX e INTERMAX mediante el Protocolo de Inicio de Sesión (SIP) de la red de telefonía fija de FIBERMAX con las redes de telefonía móvil (OMV), fija, portador local y de larga distancia de INTERMAX.', 'Soporte', 3, 3, 2, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-09-01 13:28:05', '2025-10-22 20:23:01'),
(149, '2025-09-01', 'Análisis y revisión', 14, 'Elaboración de carta a fin de presentaremos el detalle específico de cada punto discrepante que no permitió la suscripción del acuerdo de interconexión entre FIBERMAX y CLARO ', 'Soporte', 3, 3, 2, 'Completo', 4, 0, 1, 3, NULL, NULL, '2025-09-01 13:32:11', '2025-09-01 19:12:57'),
(150, '2025-09-04', 'Análisis y revisión', 14, 'Reunión con INTEGRATEL a fin de atender la orden de servicio para la implementación de SMS', 'Soporte', 3, 3, 1, 'Completo', 4, 0, 1, 3, NULL, NULL, '2025-09-01 13:36:26', '2025-09-04 17:23:38'),
(151, '2025-09-30', 'Análisis y revisión', 14, 'Adecuación de los comentarios del proyecto de norma Antispam (2-9-25) (JACY) (30 min) [COMPLETO] | Elaboración de correo para el desistimiento de la interconexión INTERMAX_FIBERMAX (3-9-25) (JACY 15 min) [COMPLETO] | Correo a Rafael para solicitar antecedentes de OMV (3-9-25) (JACY 10 min) [COMPLETO] | Trasladar correo a Rafael respecto al estado de la solicitud de la numeración (8-9-25) (JACY 5 min) [COMPLETO] | Revisión del Mandato con ENTEL asociado a la 3era adenda (10-9-25) (JACY) (30 min) [COMPLETO] | Se brindo respuesta a consulta respecto a la inclusión de portador local en la adenda de INTERMAX con INTEGRATEL (10-9-25) (JACY) (5 min) [COMPLETO] | Coordinaciones realizadas con DPRC respecto a los MC de INTEGRATEL y CLARO (15-9-25) (JACY) (20 min) [COMPLETO] | Revisión de orden de servicio y respuesta a consultas planteadas respecto de la información a consignar (18-9-25) (JACY) (30 min) | Presentación y preparación previa a reunión para el inicio del servicio portador local conmutado y no conmutado (23-9-25) (JACY) (30 min) | Audio con Ing. Freddy (OSIPTEL) a fin de aclara el objeto de las fiscalizaciones INTEGRATEL-CLARO (24-9-25) (JACY) (5 min)', 'Soporte', 3, 3, 3, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-09-01 13:37:42', '2025-09-30 19:23:56'),
(152, '2025-09-15', 'Análisis y revisión', 14, 'Elaboración de carta para trasladar orden de servicio a BITEL y trasladar sustentos que dejen precedente a un inicio de controversia por la no implementación del protocolo SIP con SS7 en simultaneo', 'Soporte', 3, 3, 3, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-09-01 13:46:33', '2025-09-17 14:09:03'),
(153, '2025-09-08', 'Análisis y revisión', 6, 'Revisión normativa para atención de consultas remitidas por Julio Cieza sobre suspensión de servicio por falta de pago: comunicaciones a OSIPTEL, tratamiento de pagos parciales, determinación de pagos mensuales en Contrato WSA y compensación con pagos por Contratos OBC.', 'Soporte', 4, 4, 2, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-09-01 16:51:13', '2025-09-09 23:33:53'),
(154, '2025-10-27', 'Análisis y revisión', 17, 'Lineamientos en base al Contrato WSA para renegociación de precios con INTEGRATEL.', 'Soporte', 4, 4, 1, 'Anulado', 6, 0, 0, 0, NULL, NULL, '2025-09-01 16:53:53', '2025-10-27 14:32:28'),
(155, '2025-09-30', 'Horas audio', 14, 'Correo de respuesta a la consulta sobre la viabilidad de que INTERMAX le brinde el servicio portador local para la interconexión con BITEL (2-9-25) (JACY 15 min) [COMPLETO] | Correo respecto a la implementación del mandato FIBERMAX-ENTEL (8-9-25) (JACY 10 min) | Se brindo respuesta a consulta respecto al recurso especial del mandato de FIBERMAX con INTEGRATEL (10-9-25) (JACY) (5 min) [COMPLETO] | ', 'Soporte', 3, 3, 1, 'Completo', 4, 0, 1, 3, NULL, NULL, '2025-09-02 16:48:04', '2025-09-30 19:28:24'),
(156, '2025-09-03', 'Análisis y revisión', 7, 'Revisión de consultas remitida por Kazhia F. respecto de la gestión operativa de los trámite del FUIIT y FTA, así de la medición de parámetros. Se brindaron lineamientos generales en función a lo indicado en la norma aplicable.', 'Soporte', 4, 4, 2, 'Completo', 9, 0, 1, 4, NULL, NULL, '2025-09-02 20:56:20', '2025-09-08 20:41:51'),
(157, '2025-09-02', 'Reunión', 7, 'Reunión solicitada por Julio Cieza para presentar sus consultas ante análisis de AMPARA sobre la posibilidad de entablar denuncia a OSIPTEL por barreras burocráticas. Asimismo, se trataron puntos respecto de otros entregables.', 'Soporte', 4, 4, 1, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-09-02 21:31:22', '2025-09-04 20:43:58'),
(158, '2025-09-30', 'Horas audio', 1, 'Consultas de Julio con Jacy respecto de comunicación a OSIPTEL por suspensión por falta de pago (1.09.2025) // Consultas de Julio con Gustavo sobre el de proceso de solicitud para acceso y uso de infraestructura mediante OBC (2 y 3.09.2025) // Consultas de Julio con ambos socios sobre denuncia a OSIPTEL por barreras burocráticas (5.09.2025) // Audio de Julio con Gustavo sobre caso de falta de energía en rack y cláusula NMF (9.09.2025) // Revisión y envío de información remitida por PRONATEL sobre contratos de GILAT (9.09.2025) // Audio de Julio con Gustavo sobre suspensión por falta de pago (10.09.2025) // Audio de Julio con Juan Carlos sobre procedimiento de reclamos TRASU y procedimiento de reclamos contractual con INTEGRATEL (17.09.2025) // Audio de Julio con Gustavo sobre negativa a contratar en un mismo anexo de servicio y otros entregables (18.09.202) // Revisión de política sobre suspensión, corte y baja del servicio por falta de pago (18.09.2025) // Absolución de consulta sobre posibilidad de replicar argumentos para denunciar barrera burocrática en mercado N°35 (30.09.2025).', 'Soporte', 6, 4, 4, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-09-03 14:13:14', '2025-09-30 20:59:04'),
(159, '2025-10-31', 'Horas audio', 14, '[PENDIENTE]', 'Soporte', 3, 3, 1, 'Anulado', 4, 0, 0, 0, NULL, NULL, '2025-09-03 15:41:38', '2025-10-24 21:55:44'),
(160, '2025-09-02', 'Análisis y revisión', 2, 'Identificación de la normativa aplicable a cada cliente y envío de su agenda regulatoria.', 'Horas Internas', 6, 2, 3, 'Completo', 11, 0, 1, 6, NULL, NULL, '2025-09-05 21:14:32', '2025-09-05 21:14:32'),
(161, '2025-09-05', 'Análisis y revisión', 31, 'Elaboración del Boletín Regulatorio - Agosto', 'Horas Internas', 6, 2, 3, 'Completo', 11, 0, 1, 6, NULL, NULL, '2025-09-05 21:15:43', '2025-09-05 21:15:43'),
(162, '2025-09-22', 'Análisis y revisión', 17, 'Actualización de informe para PANGEACO sobre análisis a la Cláusula 5.01.9 del Contrato WSA, en base a revisión de su última traducción (5.09.2025) // Revisión de norma que actualiza Anexo III del Reglamento Ambiental del sector Comunicaciones para informar a clientes (22.09.2025)', 'Horas Internas', 4, 2, 2, 'Completo', 11, 0, 1, 2, NULL, NULL, '2025-09-05 21:51:45', '2025-10-01 08:10:05'),
(163, '2025-09-15', 'Análisis y revisión', 15, 'Elaboración de comentarios a los descargos realizados por ENTEL al proyecto de mandato, adicionalmente se incorporo el desistimiento de la implementación del servicio de datos.', 'Soporte', 3, 3, 3, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-09-08 14:09:52', '2025-09-15 17:30:11'),
(165, '2025-11-13', 'Análisis y revisión', 14, 'Elaboración de PPT a fin de evidenciar la conducta anticompetitiva de BITEL frente a la INTERCONEXIÓN y Acceso a fin de exponer frente a GG OSIPTEL', 'Soporte', 3, 3, 4, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-09-08 17:53:27', '2025-11-14 15:25:51'),
(166, '2025-09-30', 'Horas audio', 33, 'Coordinación con Javier respecto al requerimiento de información respecto a los aporte al PRONATEL (5-9-25) (SOCIOS 30 min) | Coordinaciones internas con especialista en aportes regulatorios (OSIPTEL/MTC) a fin de evaluar situacion de incumplimiento de DOLPHIN (5-9-25) (SOCIOS 30min) | Asesoría sobre contrato de arrendamiento de circuitos con Airwave sobre el marco de una acción de supervisión de inicio de operaciones de portador local (8-9-25) (SOCIOS 20 min) |', 'Soporte', 6, 3, 2, 'Completo', 2, 0, 1, 3, NULL, NULL, '2025-09-08 22:18:01', '2025-09-30 20:47:01'),
(167, '2025-09-05', 'Análisis y revisión', 14, 'Analisis de requerimiento de información respecto a la supervisión de aportes al PRONATEL, lectura del expediente y ayuda memoria de comunicaciones. Adicionalmente se realizó un análisis del calculo de infracción por incumplimiento al requerimiento de información.', 'Soporte', 3, 3, 2, 'Completo', 2, 0, 1, 3, NULL, NULL, '2025-09-08 22:26:35', '2025-09-08 22:26:35'),
(168, '2025-09-10', 'Reunión', 17, 'Reunión para presentar estado y realizar seguimiento a temas abiertos en torno al inicio de operaciones del servicio portador local conmutado. Se brindaron sugerencias respecto de la obtención de permisos para instalar infraestructura de telecomunicaciones, así como parar definir los alcances sobre la definición del monto de inversión para la misma en el contrato que tiene con URBI.', 'Soporte', 4, 4, 1, 'Completo', 9, 0, 1, 4, NULL, NULL, '2025-09-09 23:47:59', '2025-09-11 20:12:24'),
(169, '2025-09-10', 'Análisis y revisión', 12, 'Análisis y revisión normativa para absolver consultas de Giovanna Piskulich sobre el tratamiento regulatorio de las tarifas promocionales respecto de las negociaciones que realiza PANGEACO con otras empresas operadoras. Se envió correo al respecto.', 'Soporte', 4, 4, 1, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-09-11 20:27:22', '2025-09-11 20:27:22'),
(170, '2025-09-11', 'Reunión', 7, 'Reunión solicitada por Julio Cieza para presentar avances e intercambiar comentarios respecto de la elaboración de la denuncia a OSIPTEL ante el INDECOPI por la emisión de barrerar burocráticas', 'Soporte', 4, 4, 1, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-09-11 20:46:33', '2025-09-11 20:46:33'),
(171, '2025-10-15', 'Análisis y revisión', 3, 'Elaboración de presentación conteniendo el detalle del último seguimiento que AMPARA realizó a las obligaciones de PRISONTEC en materia de datos personales (hasta febrero de 2024), el cumplimiento de metas cumplidas y entregables elaborados. Asimismo, se incluyó la revisión al estado actual de inscripción de sus bancos de datos y el listado de obligaciones que se establecieron posterior al último seguimiento (Reglamento vigente en 2025).', 'Soporte', 6, 4, 3, 'Completo', 8, 0, 1, 4, NULL, NULL, '2025-09-12 16:57:02', '2025-10-31 23:02:39'),
(172, '2025-09-22', 'Reunión', 17, 'Reunión solicitada por Giovanna Piskulich y Julio Cieza sobre publicación de tarifas y firma de adendas para brindar facilidades de pago en facturas. Asimismo, se trataron consultas adicionales sobre el alcance del texto de la cláusula de Nación Más Favorecida, suspensión de servicio por falta de pago, entre otros temas pendientes.', 'Soporte', 4, 4, 1, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-09-12 19:45:59', '2025-09-22 22:11:23'),
(173, '2025-09-15', 'Reunión', 11, 'Reunión solicitada por Pedro Castro para revisar proyecto de protocolo para medir disponibilidad de bloqueadores instalados en establecimientos penitenciarios. Se presentó a detalle el borrador del protocolo y se intercambiaron sugerencias al respecto.', 'Soporte', 4, 4, 2, 'Completo', 8, 0, 1, 4, NULL, NULL, '2025-09-16 01:27:19', '2025-09-16 01:27:19'),
(174, '2025-09-16', 'Análisis y revisión', 6, 'Análisis y revisión de normativa para absolución de consultas adicionales de Julio Cieza sobre suspensión de servicio por falta de pago, así como respecto de tarifas por reconexión de servicio. Las consultas se absolvieron por correo, por WhatsApp y por llamada.', 'Soporte', 4, 4, 2, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-09-17 01:30:42', '2025-09-17 01:30:42'),
(175, '2025-09-19', 'Análisis y revisión', 6, 'Análisis y revisión normativa para absolución de consultas de Julio Cieza sobre posibilidad para disponer el bloqueo lógico a INTEGRATEL para evitar que active nuevas UIC, en ejercicio de su facultad para negarse a realizar nuevas contrataciones con dicha empresa por deuda exigible. ', 'Soporte', 4, 4, 1, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-09-19 21:35:18', '2025-09-19 21:35:18'),
(176, '2025-09-18', 'Análisis y revisión', 11, 'Actualización de proyecto de protocolo para evaluación anual de indicador de disponibilidad de bloqueadores en base a comentarios y estrategia de medición brindados por el Ing. Diego Velasco.', 'Soporte', 4, 4, 1, 'Completo', 8, 0, 1, 4, NULL, NULL, '2025-09-19 21:38:39', '2025-09-23 18:50:38'),
(177, '2025-09-19', 'Reunión', 14, 'Reunión a fin de detallar el filtro aplicado por CLARO  a los SMS A2P (Google, Microsoft), además de acordar estrategia frente a las fiscalizaciones de los mandatos de interconexión con CLARO e INTEGRATEL', 'Soporte', 3, 3, 1, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-09-19 21:38:51', '2025-09-19 21:38:51'),
(178, '2025-09-26', 'Análisis y revisión', 6, 'Revisión normativa para elaborar listado de obligaciones y formalidades, solicitado por Julio Cieza, que PANGEACO debe cumplir ante la presentación de un reclamo por facturación de INTEGRATEL, en el marco del proceso regulatorio establecido por OSIPTEL (TRASU). Se elaboró un cuadro Excel con el listado total, haciendo énfasis en las acciones consultadas por el cliente (contenido de resolución, asignación de códigos de reclamo, entre otros).', 'Soporte', 4, 4, 2, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-09-19 21:42:18', '2025-09-29 18:32:54'),
(179, '2025-09-19', 'Análisis y revisión', 20, 'Analisis y revisión de 5 proyectoas sujetos al SANDBOX  fin de absolver consultas trasladadas por el MTC en relación al uso de bandas, clasificación dl servicio y asignación de espectro', 'Soporte', 3, 3, 7, 'Completo', 3, 0, 1, 3, NULL, NULL, '2025-09-22 13:34:03', '2025-09-22 15:43:59'),
(180, '2025-09-30', 'Horas audio', 20, 'Comunicación con Hector a fin de brindar alcance las observaciones planteadas por el MTC a los proyectos SANDBOX (18-9-25) (SOCIOS) (20 min) | Reunión con Hector a fin de determinar el alcance de las consultas  planteadas por el MTC y establecer parámetros técnicos de operación para el despliegue de los servicios (19-9-25) (JACY/GUSTAVO) (20 min)', 'Soporte', 3, 3, 1, 'Completo', 3, 0, 1, 3, NULL, NULL, '2025-09-22 13:37:45', '2025-09-30 19:30:02'),
(182, '2025-09-23', 'Análisis y revisión', 14, 'Elaboración de Presentaciones que detalle aspectos relevantes de la interconexión entre INTERMAX con INTEGRATEL', 'Soporte', 3, 3, 2, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-09-22 13:43:15', '2025-09-25 17:41:38'),
(183, '2025-10-06', 'Análisis y revisión', 14, 'Elaboración de carta al OSIPTEL para evidenciar conducta de CLARO por el bloqueo de SMS (GOOGLE/MICROSOFT)', 'Soporte', 3, 3, 2, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-09-22 13:43:46', '2025-10-10 18:01:27'),
(184, '2025-10-07', 'Análisis y revisión', 14, 'Elaboración de carta a fin de evidenciar la negativa de ENTEL a la interconexión', 'Soporte', 3, 3, 2, 'Completo', 4, 0, 1, 3, NULL, NULL, '2025-09-22 13:44:25', '2025-10-09 20:30:55'),
(185, '2025-09-23', 'Reunión', 23, 'Reunión a fin de evaluar requerimientos para el incio de operaciones del servicio portador local conmutado y no conmutado', 'Soporte', 3, 3, 1, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-09-22 13:45:52', '2025-09-23 15:53:08'),
(186, '2025-09-26', 'Reunión', 14, 'Reunión de acompañamiento a la fiscalización de OSIPTEL para verificar cumplimiento de Mandato de interconexión con INTEGRATEL', 'Soporte', 3, 3, 8, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-09-22 13:49:06', '2025-09-29 13:37:27'),
(187, '2025-09-30', 'Análisis y revisión', 23, 'Elaboración de informe de Evaluación de la Renovación de la Concesión única para Dolphin Telecom del Perú S.A.C., presentando una evaluación integral que permita determinar el periodo estimado de renovación de la concesión única de DOLPHIN TELECOM, utilizando la Norma que establece los Criterios Generales para la Renovación de Concesiones de Servicios Públicos de Telecomunicaciones y los Métodos de Evaluación del Cumplimiento de las Obligaciones de las empresas concesionarias de servicios públicos de telecomunicaciones” aprobada mediante Decreto Supremo N°008-2021-MTC. Además se recoge la manera cómo DOLPHIN TELECOM ha venido cumpliendo con sus obligaciones regulatorias conforme al marco normativo y contractual vigente', 'Soporte', 3, 3, 6, 'Completo', 2, 0, 1, 3, NULL, NULL, '2025-09-22 14:59:28', '2025-10-01 00:36:12'),
(188, '2025-09-23', 'Reunión', 1, 'Reunión a fin de absolver consultas respecto a los 4 proyectos SANDBOX que se enviaran al MTC, se detallaron canalizaciones y empleo de bandas actualmente y los servicios prestados efectivamente', 'Soporte', 6, 3, 1, 'Completo', 3, 0, 1, 3, NULL, NULL, '2025-09-23 17:18:11', '2025-09-23 17:20:24'),
(189, '2025-09-23', 'Análisis y revisión', 11, 'Revisión a protocolo actualizado para la medición de indicadores de calidad en bloqueadores, solicitado por Pedro Castro. Se envió documento con comentarios y se tuvo una llamada previa.', 'Soporte', 4, 4, 1, 'Completo', 8, 0, 1, 4, NULL, NULL, '2025-09-23 19:04:23', '2025-09-23 19:04:23'),
(190, '2025-09-23', 'Análisis y revisión', 1, 'Adecuación de los 4 proyectos SANDBOX considerando las precisiones técnicas respecto a bandas, canalización, naturaleza del servicio y equipos empleados dentro de cada proyecto', 'Soporte', 6, 3, 1, 'Completo', 3, 0, 1, 3, NULL, NULL, '2025-09-23 21:51:23', '2025-09-23 21:51:23'),
(191, '2025-09-24', 'Análisis y revisión', 14, 'Carta al MTC a fin de trasladar oficio respecto al pronunciamiento sobre la no regulación de alfanuméricos al Director General de la Dirección General de Fiscalizaciones y Sanciones en Comunicaciones.', 'Soporte', 3, 3, 1, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-09-24 15:35:10', '2025-09-25 16:44:39'),
(192, '2025-09-26', 'Análisis y revisión', 1, 'Revisión de: i) norma qué modifica Anexo de Protocolo Técnico para medir señales radioeléctricas en bloqueadores Prisontec y ii) proyecto de norma para modificar Reglamento Ambiental de Sector Comunicaciones. Se envió revisión a PRISONTEC y a demás clientes para su conocimiento y fines pertinentes ', 'Horas Internas', 4, 2, 1, 'Completo', 11, 0, 1, 4, NULL, NULL, '2025-09-26 23:18:46', '2025-09-26 23:18:46'),
(193, '2025-10-14', 'Análisis y revisión', 25, 'Analisis y revisión de los 10 formatos asociados a la Norma de Requerimiento de Información (NRIP) y la posibilidad de realizar o no la subsanación voluntaria frente al reporte de información inexacta durante los 2 primeros trimestres del 2025 respecto a la cantidad e Líneas en servicio de PRISONTEC.', 'Soporte', 3, 4, 3, 'Completo', 8, 0, 1, 4, NULL, NULL, '2025-09-26 23:22:23', '2025-10-14 22:48:21'),
(194, '2025-10-03', 'Análisis y revisión', 14, 'Carta con los comentarios a los argumentos de CLARO al proyecto de mandato de interconexión para el servicio de SMS', 'Soporte', 3, 3, 3, 'Completo', 4, 0, 1, 3, NULL, NULL, '2025-09-29 13:36:37', '2025-10-03 19:23:40'),
(195, '2025-09-30', 'Análisis y revisión', 4, 'Revisión e identificación de normas de telecomunicaciones en el diario oficial El Peruano, página oficial de OSIPTEL y agendas para sesiones de Consejo Directivo para realizar actualización de Alerta Normativa durante el mes de setiembre. Adecuación de la plantilla y envío a contactos.', 'Horas Internas', 4, 2, 3, 'Completo', 11, 0, 1, 4, NULL, NULL, '2025-09-29 18:59:22', '2025-09-29 18:59:22'),
(196, '2025-09-30', 'Análisis y revisión', 23, 'Reunión de fiscalización del MTC para verificar el inicio de operaciones del servicio portador local conmutado y no conmutado', 'Soporte', 3, 3, 1, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-09-30 19:27:23', '2025-09-30 19:27:23'),
(197, '2025-09-29', 'Análisis y revisión', 25, 'Analisis y revisión de carta y anexos de respuesta al oficio del MTC respecto al cumplimiento de instalación de internet fijo de banda ancha en 5 colegios en el departamento de Junín, se realizo revisión de actas, verificación de velocidad garantizada y obligaciones adicionales requeridas por el MTC.', 'Soporte', 3, 3, 1, 'Completo', 2, 0, 1, 3, NULL, NULL, '2025-09-30 19:42:21', '2025-09-30 19:42:21'),
(198, '2025-10-02', 'Análisis y revisión', 20, 'Elaboración de correo a fin de detallar análisis de naturaleza del servicio de la provisión de una VPN, detalle de informe de pronunciamiento de OSIPTEL y evaluación de características del servicio', 'Soporte', 3, 3, 1, 'Completo', 3, 0, 1, 3, NULL, NULL, '2025-10-03 17:44:36', '2025-10-03 17:44:36'),
(199, '2025-10-03', 'Reunión', 16, 'Reunión a fin de detallar estrategia regulatoria para llevarlo a Mandato a BITEL por las localidades contempladas en el concurso de 5G de la bolsa 5', 'Soporte', 4, 3, 1, 'Completo', 3, 0, 1, 3, NULL, NULL, '2025-10-03 17:46:00', '2025-10-03 17:46:00'),
(200, '2025-10-14', 'Reunión', 16, 'Análisis de aportes realizado en el año 2022 y estrategia frente al impago de la DDJJ rectificatorias; además se evaluó estrategia frente a la posible obligación a  BITEL  a que los contrate como OIMR si se indica que se va a desplegar en unos sitios que están en la lista de localidades del concurso.', 'Soporte', 4, 3, 1, 'Completo', 3, 0, 1, 3, NULL, NULL, '2025-10-03 17:48:04', '2025-10-14 22:50:26'),
(201, '2025-10-02', 'Análisis y revisión', 24, 'Analisis y elaboración de correo que absuelve la interpretación de la normas de Metas de Uso, considerando las fechas de instalación de las estaciones radioeléctricas del servicio Tetra de Dolphin Telecom.', 'Soporte', 3, 3, 3, 'Completo', 2, 0, 1, 3, NULL, NULL, '2025-10-03 19:21:53', '2025-10-03 19:21:53'),
(202, '2025-10-31', 'Horas audio', 1, 'Revisión y adecuación de carta para brindar respuesta al requerimiento solicitado por OSIPTEL respecto al periodo de validez de la interconexión con INTEGRATEL (3-10-25) (JACY/SOCIO) (15 min) | Audio con MTC y Rafael  para revisar estado de la solicitud de recurso numérico (15-10-20) (SOCIOS) (30 min) | Análisis y elaboración de correo que contempla la estrategia frente al MTC por la solicitud de numeración para el servicio de telefonía fija (17-10-25) (PAOLO) (25 min) | Reunión previa para establecer estrategia frente al MTC respecto a la solicitud de numeración (17-10-25) (JACY/SOCIOS/PAOLO) (30 min) | Elaboración de correo a fin brindar alcance de la solicitud de emisión de proyecto de mandato planteada por BITEL  a fin de modificar la clausula Antispam (23-10-25) (JACY) (20 min)', 'Soporte', 4, 3, 2, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-10-03 19:31:04', '2025-10-27 16:50:39'),
(203, '2025-10-02', 'Reunión', 1, 'Reunión solicitada por William Ordoñez para la absolución de consultas pendientes en última reunión de setiembre (monto de inversión y gestión de permisos FTA/FUIIT). Asimismo, se presentaron nuevas consultas sobre facturaciones, uso de bandas libres e implementación de infraestructura.', 'Soporte', 4, 4, 1, 'Completo', 9, 0, 1, 4, NULL, NULL, '2025-10-03 20:03:24', '2025-10-03 20:03:24'),
(204, '2025-10-03', 'Análisis y revisión', 6, 'Revisión de proyecto de norma para modificar Norma de Condiciones de Uso. Se envió correo con resumen del proyecto a todos los clientes para conocimiento y eventual envío de comentarios al OSIPTEL.', 'Horas Internas', 4, 2, 1, 'Completo', 11, 0, 1, 4, NULL, NULL, '2025-10-03 20:11:06', '2025-10-03 20:11:06'),
(205, '2025-10-31', 'Análisis y revisión', 24, 'Análisis y revisión de documentos regulatorios, informes y, notas en líneas y noticias nacionales e internacionales para elaborar informe sobre perfil institucional y regulatorio (que detalle títulos habilitantes y espectro asignado) de STARLINK. Asimismo, se incluyeron algunos alcances adicionales y recomendaciones que permitiría identificar el impacto de señales satelitales utilizados en servicios móviles, en el servicio de bloqueo y/o inhibición proporcionado por PRISONTEC en los establecimientos penitenciarios. Se adjuntó documentación oficial sobre STARLINK que fue solicitado por acceso a la información ante el MTC, para efectos del presente entregable.', 'Soporte', 12, 4, 5, 'Completo', 8, 0, 1, 4, NULL, NULL, '2025-10-03 20:14:57', '2025-10-31 23:36:31'),
(206, '2025-10-14', 'Análisis y revisión', 7, 'Análisis y revisión de normativa y documentos afines para elaborar informe que contenga estrategia, riesgos y recomendaciones para interponer denuncia por barreras burocráticas en resolución que determinó la inexistencia de Proveedores Importantes en Mercado N°25, considerando sus particularidades que lo diferencian del Mercado N°35.', 'Soporte', 4, 4, 4, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-10-03 20:17:30', '2025-10-30 15:44:15'),
(207, '2025-10-31', 'Horas audio', 1, 'Presentación de solicitud de acceso a la información de expediente de reconsideración de INTEGRATEL ante resolución que lo nombró como Proveedor Importante en Mcdo. 35 en 2019 (3.10.2025) // Absolución de consulta de Julio sobre aportes por ingresos de liberación de interferencias (9.10.2025) // Absolución de consulta de Julio con Juan Carlos sobre conexión tarifaria de Contrato WSA con Contrato por OBC (16.10.2025) // Absolución de consultas de Julio con Gustavo sobre norma que dispuso regulación diferencia al abonado corporativo (16.10.2025) // Revisión de carta para comunicar suspensión por falta de pago a INTEGRATEL y absolución de consultas sobre fecha efectiva de suspensión (20.10.2025) // Recopilación, revisión y envío de documentación sobre expediente de reconsideración enviada por OSIPTEL (21.10.2025)', 'Soporte', 4, 4, 3, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-10-03 20:21:14', '2025-10-31 23:06:21'),
(208, '2025-10-08', 'Análisis y revisión', 24, 'Elaboración de informe a fin de brindar alcance respecto a traslado de espectro a otra empresa operadora sin concesión móvil', 'Soporte', 3, 3, 3, 'Anulado', 2, 0, 0, 0, NULL, NULL, '2025-10-06 14:12:27', '2025-10-31 20:50:18'),
(209, '2025-10-09', 'Reunión', 14, '	Reunión de acompañamiento a la fiscalización de OSIPTEL para verificar cumplimiento de Mandato de interconexión con CLARO', 'Soporte', 3, 3, 7, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-10-06 14:36:40', '2025-10-09 20:34:16'),
(210, '2025-10-10', 'Análisis y revisión', 14, 'Elaboración de carta a fin de remitir descargos a la negativa de INTEGRATEL a la interconexión móvil con INTERMAX como OMV', 'Soporte', 3, 3, 2, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-10-06 14:41:22', '2025-10-10 18:00:58'),
(211, '2025-10-31', 'Horas audio', 14, 'Elaboración de correo a fin de brindar alcance de las obligaciones de DOLPHIN frente a la vigencia del mandato de interconexión (OMV) con INTEGRATEL (6-10-25) (JACY) (45 min) | Coordinaciones con Monica y César Valdría a fin de brindar respuesta al recurso de INTEGRATEL al mandato de interconexión (30-10-25) (SOCIOS) (15 min)', 'Soporte', 3, 3, 1, 'Completo', 2, 0, 1, 3, NULL, NULL, '2025-10-06 14:47:04', '2025-10-31 23:03:13'),
(212, '2025-10-07', 'Análisis y revisión', 14, 'Elaboración de Presentaciones que detalle aspectos relevantes de la interconexión entre INTERMAX con CLARO', 'Soporte', 3, 3, 1, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-10-06 14:48:39', '2025-10-09 20:35:11'),
(213, '2025-10-06', 'Análisis y revisión', 31, 'Búsqueda y recopilación de información para elaborar el Boletín Regulatorio, correspondiente al mes de septiembre de 2025.', 'Horas Internas', 4, 2, 3, 'Completo', 11, 0, 1, 2, NULL, NULL, '2025-10-06 16:11:27', '2025-10-10 20:55:26'),
(214, '2025-10-13', 'Análisis y revisión', 25, 'Prueba.', 'Soporte', 12, 12, 2, 'Anulado', 9, 0, 0, 0, NULL, NULL, '2025-10-06 18:31:17', '2025-10-06 18:53:33'),
(215, '2025-10-06', 'Reunión', 7, 'Reunión solicitada por Julio Cieza para revisar las acciones legales que PANGEACO puede considerar ante la reciente oficialización, por parte de OSIPTEL, para declarar que actualmente no existen Proveedores Importantes en el Mercado N°35.', 'Soporte', 4, 4, 2, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-10-06 21:08:31', '2025-10-30 15:42:12'),
(216, '2025-10-16', 'Análisis y revisión', 33, 'Adecuación de comunicación al OSIPTEL para precisar porcentaje de alícuota aplicable al año 2022 para el servicio B2B y OIMR.', 'Soporte', 3, 3, 4, 'Completo', 3, 0, 1, 3, NULL, NULL, '2025-10-07 14:21:31', '2025-10-20 16:16:46'),
(217, '2025-10-06', 'Reunión', 33, 'Reunión a fin para precisar porcentaje de alícuota aplicable al año 2022 para el servicio B2B y OIMR.', 'Soporte', 3, 3, 1, 'Completo', 3, 0, 1, 3, NULL, NULL, '2025-10-07 14:22:35', '2025-10-07 14:22:35'),
(218, '2025-10-31', 'Horas audio', 33, 'Audio con OSIPTEL a fin de solicitar ampliación del requerimiento de información respecto de la fiscalización de aportes del año 2022 (7-10-25) (SOCIOS) (20 min) | Audio con Sheyla a fin de solicitar prórroga para brindar información al OSIPTEL respecto de la fiscalización de aportes del año 2022 (7-10-25) (SOCIOS) (20 min) | Elaboración de correo a fin de brindar alcances respecto a posibles incumplimientos en los pagos de aportes 2022, así como brindar alcance de la posición del OSIPTEL respecto a la alícuota aplicable a los servicios provistos por IPT (7-10-25) (PAOLO) (20 min) | Audio con Sheyla respecto al impago de los aportes del año 2022 (9-10-25) (SOCIOS) (15 min) | Reunión suspendida de tema de aportes 2022 y la obligatoriedad de OIMR con BITEL (13-10-25) (SOCIOS) (15 min) | Reunión con equipo IPT a fin de analizar el punto 4 de la carta de requerimiento realizado por el OSIPTEL (17-10-25) (JACY) (25 min) | audio con Rosita Abad de IPT sobre la presentación que tienen hoy   con el Director de Politicas del MTC(17-10-25) (SOCIOS) (15 min) | Revisión de la adecuación realizada a la comunicación que se trasladará a Bitel respecto a brindar facilidades en localidades de licitación 5G (22-10-25) (GUSTAVO) (25 min)', 'Soporte', 3, 3, 3, 'Completo', 3, 0, 1, 3, NULL, NULL, '2025-10-07 22:13:26', '2025-10-27 16:44:10'),
(219, '2025-10-23', 'Análisis y revisión', 14, 'Elaboración de respuesta a negativa de la implementación de la interconexión con BITEL debido a supuesta “imposibilidad jurídica” de que el sistema SS7 y el protocolo SIP puedan coexistir.', 'Soporte', 3, 3, 3, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-10-10 18:19:11', '2025-10-24 16:55:36'),
(220, '2025-10-31', 'Horas audio', 1, 'Correo absolviendo consulta adicional de Pedro Castro sobre proyecto de modificación a Reglamento de Gestión Ambiental (9.10.2025) // Audio de Viviana Sánchez y Tito Fernández con Juan Carlos sobre informe de videollamadas (23.10.2025)', 'Soporte', 4, 4, 1, 'Completo', 8, 0, 1, 4, NULL, NULL, '2025-10-10 20:51:14', '2025-10-31 19:06:11'),
(221, '2025-10-21', 'Análisis y revisión', 7, 'Análisis de respuestas de OSIPTEL en informe y matriz de comentarios de la norma que determinó la inexistencia de Proveedores Importantes en el Mercado N°35, ante argumentos presentados por PANGEACO (Estudio Rubio) al proyecto elevado para comentarios de dicha norma.', 'Soporte', 4, 4, 2, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-10-10 20:54:25', '2025-10-21 23:19:14'),
(222, '2025-10-23', 'Análisis y revisión', 14, 'PRUEBA | Informe', 'Soporte', 3, 3, 2, 'Anulado', 5, 0, 0, 0, NULL, NULL, '2025-10-13 15:12:10', '2025-10-14 14:10:27'),
(223, '2025-10-14', 'Análisis y revisión', 33, 'Recopilación de comunicaciones entre IPT y OSIPTEL por el tema de Aporte por Regulación en 2022, así como el análisis de la información respecto a las declaraciones juradas originales, las rectificatorias y los documentos presentados durante el 2025 sobre el cambio en la base imponible y alícuota.', 'Soporte', 3, 3, 2, 'Completo', 3, 0, 1, 3, NULL, NULL, '2025-10-14 22:54:55', '2025-10-14 22:54:55'),
(224, '2025-10-20', 'Análisis y revisión', 16, 'Análisis y revisión de normativa y mandatos afines para elaborar informe que contiene alcances para plantear estrategia y emitr recomendaciones en torno a la firma del acuerdo o mandato de provisión de facilidades de acceso y transporte de IPT, en su condición de OIMR, en favor de BITEL, en su condición de OMR. Asimismo, se elaboró proyecto de carta de ofrecimiento de facilidades, en atención a las formalidades señaladas en la norma.', 'Soporte', 4, 3, 3, 'Completo', 3, 0, 1, 3, NULL, NULL, '2025-10-14 23:05:04', '2025-10-20 16:15:51'),
(226, '2025-10-17', 'Reunión', 26, 'Reunión con el MTC a fin de detallar sustentos a la solicitud de recurso numérico para el servicio de telefonía fija', 'Soporte', 12, 3, 1, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-10-16 16:14:46', '2025-10-17 16:42:16'),
(227, '2025-10-24', 'Análisis y revisión', 6, 'Análisis y revisión de normativa y documentos asociados para elaborar informe que brindó respuesta a las consultas planteadas por el cliente sobre norma que dispuso regulación diferenciada para Abonados Corporativos, en torno a la aplicación a los contratos vigentes de PANGEACO y los próximos a firmar, así como, sobre los alcances a considerar para la suspensión, corte y baja del servicio. Se brindaron recomendaciones y alternativas de actuación.', 'Soporte', 4, 4, 4, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-10-17 20:13:13', '2025-10-31 22:57:11'),
(228, '2025-11-04', 'Análisis y revisión', 26, 'Recopilación de información respecto al uso de numeración de INTERMAX en los departamentos donde brinda servicio durante el año 2024, así como la estimación de las previsiones de uso de los años 2024 y 2025. Elaboración de la carta junto con la data recopilada en cumplimiento de Art. 15 del Reglamento de Numeración que establece la remisión periódica del Uso de la Numeración asignada.', 'Soporte', 12, 3, 3, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-10-20 13:37:12', '2025-11-05 22:14:32'),
(229, '2025-10-22', 'Análisis y revisión', 26, 'Elaboración de carta a fin de dar mejor detalle comercial al requerimiento de numeración realizado al MTC, se detallo sustento comercial y además se citaron informes de análisis del sector empresarial emitidos por el OSIPTEL que refleje el incremento del mercado al cual INTERMAX brindara sus servicios.', 'Soporte', 12, 3, 3, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-10-20 13:39:02', '2025-10-23 16:21:27'),
(230, '2025-10-20', 'Reunión', 25, 'Reunión para evaluar la remisión de comentarios al Proyecto de Norma que modifica el Reglamento de Aportes para OSIPTEL, respecto a la Doble imposición y solicitud de tasa diferenciada del Aporte por Regulación aplicable a los Operadores Móviles Virtuales (OMV).', 'Soporte', 12, 12, 1, 'Completo', 2, 0, 1, 12, NULL, NULL, '2025-10-20 13:39:51', '2025-10-22 15:18:07');
INSERT INTO `liquidacion` (`idliquidacion`, `fecha`, `asunto`, `tema`, `motivo`, `tipohora`, `acargode`, `lider`, `cantidahoras`, `estado`, `idcontratocli`, `idpresupuesto`, `activo`, `editor`, `enlace_onedrive`, `fecha_completo`, `registrado`, `modificado`) VALUES
(231, '2025-10-31', 'Análisis y revisión', 14, 'Elaboración de escrito a Osiptel con los antecedentes y magnificando su inacción que ha llevado al bloqueo de la interconexión por parte de BITEL y el perjuicio afectuado a INTERMAX', 'Soporte', 3, 3, 5, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-10-20 13:44:15', '2025-11-03 15:43:35'),
(232, '2025-10-20', 'Análisis y revisión', 25, 'Análisis y revisión de la normativa de Aportes por Regulación (OSIPTEL, FITEL, y TEC) aplicable a los servicios de PAPSAC (Valor Añadido y Portadores). Se determinó el alcance de las obligaciones de pago, la periodicidad de las DDJJ los pagos, las alícuotas diferenciadas y los servicios sujetos según tipo de aporte. Se elaboró el Informe Ejecutivo, desglosando las obligaciones por cada uno de los servicios brindados por PAPSAC (en operación y los que están próximos a entrar en operación) así como tablas con ejemplos de actividades que constituyen la base imponible para cada servicio. Finalmente, se incluyó una matriz de afectación de aportes por clasificación regulatoria a modo de resumen.', 'Soporte', 12, 12, 3, 'Completo', 9, 0, 1, 12, NULL, NULL, '2025-10-20 18:12:59', '2025-10-20 18:12:59'),
(233, '2025-10-20', 'Reunión', 14, 'Reunión a fin de establecer estrategias frente al bloqueo total de la interconexión por parte de BITEL, además de coordinar paso a seguir respecto al procedimiento de aprobación del contrato de interconexión fibermax con intermax.', 'Soporte', 3, 3, 1, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-10-21 15:52:10', '2025-10-21 15:52:10'),
(234, '2025-10-21', 'Reunión', 20, 'Reunión a fin de establecer l clasificación y naturaleza del servicio a brindar mediante wifi en plazas por IPT', 'Soporte', 3, 3, 1, 'Completo', 3, 0, 1, 3, NULL, NULL, '2025-10-21 21:42:16', '2025-10-21 21:42:16'),
(235, '2025-10-23', 'Análisis y revisión', 25, 'Elaboración del comentario listo para su presentación al proyecto de Norma que modifica el Reglamento de Aportes al OSIPTEL, sustentando la necesidad de deducir los Cargos de Acceso (en el caso de los OMV como Dolphin) de la base de cálculo del Aporte por Regulación. La argumentación se centró en la analogía funcional de dichos cargos respecto a los Cargos de Interconexión, que ya son deducibles.', 'Soporte', 12, 12, 5, 'Completo', 2, 0, 1, 12, NULL, NULL, '2025-10-23 14:37:54', '2025-10-24 20:14:54'),
(236, '2025-12-01', 'Análisis y revisión', 14, 'Elaboración de carta a Claro a fin de trasladar logs que solicitan respecto al bloqueo de SMS  OTPs (MICRSOFT /GOOGLE)', 'Soporte', 3, 3, 2, 'Completo', 5, 0, 1, 3, 'https://1drv.ms/u/c/8273a3182564d1ab/IQAcLwcPKRYuQLTd26ffm2fPASIj_r5ttadHZGi-Cejr-gs?e=NaqXdC', '2025-12-01', '2025-10-24 19:44:22', '2025-12-01 21:03:13'),
(237, '2025-11-06', 'Análisis y revisión', 14, 'Análisis y revisión a fin de emitir comentarios al proyecto de mandato de interconexión del servicio de telefonía, empleando protocolo SIP, entre FIBERMAX y CLARO ', 'Soporte', 3, 3, 3, 'Completo', 4, 0, 1, 3, NULL, NULL, '2025-10-24 19:46:14', '2025-11-06 17:12:22'),
(238, '2025-10-27', 'Análisis y revisión', 15, 'Elaborar comunicación al OSIPTEL a fin de solicitar un mandato de interconexión para de incluir el servicio móvil de INTERMAX como OMV a la relación vigente', 'Soporte', 3, 3, 1, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-10-24 19:48:08', '2025-10-29 23:21:46'),
(239, '2025-11-14', 'Análisis y revisión', 14, 'Recopilación y analisis de antecedentes a fin de evaluar la procedencia de las denuncias por el incumplimiento de Bitel a la implementación de la interconexión con Fibermax', 'Soporte', 3, 3, 2, 'Completo', 4, 0, 1, 3, NULL, NULL, '2025-10-24 19:49:22', '2025-11-27 20:27:48'),
(240, '2025-11-14', 'Análisis y revisión', 14, 'Recopilación y analisis de antecedentes a fin de evaluar la procedencia de las denuncias por el incumplimiento de Entel a la implementación de la interconexión de SMS con Fibermax', 'Soporte', 3, 3, 1, 'Completo', 4, 0, 1, 3, NULL, NULL, '2025-10-24 19:50:56', '2025-11-27 20:23:56'),
(241, '2025-11-04', 'Análisis y revisión', 24, 'Elaboración de una guía \"paso a paso\" detallada que contiene todos los requisitos legales, técnicos y económicos exigibles por el MTC para la transferencia de la Concesión (incluyendo el Espectro asignado). Esto incluyó los requisitos específicos tanto para la empresa transferente como para la cesionaria.', 'Soporte', 12, 12, 5, 'Completo', 2, 0, 1, 12, NULL, NULL, '2025-10-24 20:44:30', '2025-11-05 22:10:42'),
(242, '2025-10-24', 'Análisis y revisión', 33, 'Elaboración del comentario general al proyecto de Norma que modifica el Reglamento de Aportes al OSIPTEL, sustentando la necesidad de la exclusión de los ingresos generados por la Facilidad de Acceso de la base imponible del Aporte por Regulación (APR), dentro del marco de los OIMR, en los cuales el servicio principal ofrecido está compuesto por facilidades de transporte y facilidades de acceso. La argumentación se centró en la falta de clasificación de la Facilidad de Acceso como Servicio Público de Telecomunicaciones (SPT).', 'Soporte', 3, 3, 1, 'Completo', 3, 0, 1, 3, NULL, NULL, '2025-10-27 16:37:34', '2025-10-27 16:37:34'),
(243, '2025-10-29', 'Análisis y revisión', 24, 'Desarrollo de exposición tematica del mes de OCTUBRE, respecto al cumplimiento de Metas de Uso del espectro Radioelectrico', 'Horas Internas', 12, 2, 3, 'Completo', 11, 0, 1, 2, NULL, NULL, '2025-10-29 23:35:29', '2025-10-30 16:30:49'),
(244, '2025-10-27', 'Análisis y revisión', 7, 'Revisión de normativa aplicable, noticias nacionales e internacionales, así como de documentación asociada para plantear alcances y comentarios a exponerse en panel regulatorio sobre compartición de infraestructura y cierre de brechas que se abordará durante el Foro Conecta 2025, solicitado por Giovanna Piskulich.', 'Soporte', 4, 4, 2, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-10-30 15:35:24', '2025-10-30 15:35:24'),
(245, '2025-10-27', 'Reunión', 7, 'Reunión con Giovanna Piskulich para compartir alcances relevantes advertidos en la revisión de información, efectuada por AMPARA, para presentarlos como parte de su exposición en Foro Conecta 2025.', 'Soporte', 4, 4, 1, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-10-30 15:36:24', '2025-10-30 15:36:24'),
(246, '2025-10-28', 'Análisis y revisión', 7, 'Elaboración de pregunta y respuestas ante la misma, solicitadas por Julio Cieza, en base a experiencia nacional, internacional y buenas prácticas de PANGEACO, a fin de considerarlas para su exposición en Foro Conecta 2025.', 'Soporte', 4, 4, 1, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-10-30 15:38:25', '2025-10-30 15:38:25'),
(247, '2025-10-30', 'Análisis y revisión', 14, 'Adecuación de carta al OSIPTEL mediante la cual se presentan comentarios al recurso especial planteado por  INTEGRATEL al mandato de interconexión con DOLPHIN. Se reforzaron los comentarios vinculados a los escenarios del Informe N.º 000212-2025-DPRC/OSIPTEL, Se revisaron y adecuaron las citas normativas para mantener coherencia con la normativa vigente y evitar posibles referencias imprecisas y se excluyeron solicitudes de modificaciones considerando que del análisis resulto que estas contradecían con los argumentos planteados en la carta.\r\n', 'Soporte', 3, 12, 3, 'Completo', 2, 0, 1, 3, NULL, NULL, '2025-10-30 18:22:31', '2025-10-30 18:22:31'),
(248, '2025-11-05', 'Análisis y revisión', 14, 'Elaboración de comentarios a la solicitud de modificación de Mandato de INTERCONEXIÓN SMS realizado por BITEL, respecto a la clausula Antispam.', 'Soporte', 3, 3, 3, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-10-31 16:50:21', '2025-11-07 23:39:30'),
(249, '2025-10-31', 'Análisis y revisión', 4, 'Revisión e identificación de normas de telecomunicaciones en el diario oficial El Peruano, página oficial de OSIPTEL y agendas para sesiones de Consejo Directivo para realizar actualización de Alerta Normativa durante el mes de octubre. Adecuación de la plantilla y envío a contactos.', 'Horas Internas', 4, 2, 3, 'Completo', 11, 0, 1, 4, NULL, NULL, '2025-10-31 19:04:02', '2025-10-31 19:04:02'),
(250, '2025-10-31', 'Reunión', 23, 'Reunión respecto a consultas por el Informe de Aportes y el Inicio de Operaciones de Portador Local/LDN.  ', 'Soporte', 12, 12, 2, 'Completo', 9, 0, 1, 12, NULL, NULL, '2025-10-31 22:09:57', '2025-10-31 22:09:57'),
(251, '2025-10-31', 'Análisis y revisión', 7, 'Recopilación, revisión y análisis de documentos regulatorios, informes, notas en líneas y noticias nacionales e internacionales para elaboración de pliego de respuestas, solicitado por Giovanna Piskulich, ante preguntas planteadas en panel sobre compartición de infraestructura en Foro Conecta 2025. Se adjuntó pliego adjuntando documentos de interés para revisión del cliente.', 'Soporte', 4, 4, 4, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-10-31 23:43:20', '2025-11-03 14:57:31'),
(252, '2025-11-02', 'Análisis y revisión', 7, 'Búsqueda y revisión de documentos regulatorios, noticias, estadísticas, entre otra información para elaborar resumen ejecutivo sobre estado actual de la operación de la Red Dorsal Nacional de Fibra Óptica, solicitado por Giovanna Piskulich. Se intercambiaron diversas comunicaciones internas con el cliente y finalmente se envió un correo conteniendo dicho resumen.', 'Soporte', 4, 4, 2, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-11-03 15:02:29', '2025-11-03 15:02:29'),
(253, '2025-11-05', 'Análisis y revisión', 2, 'Agendas Regulatorias del mes de NOVIEMBRE para todos los clientes AMPARA', 'Horas Internas', 12, 2, 3, 'Completo', 11, 0, 1, 3, NULL, NULL, '2025-11-05 21:33:26', '2025-11-05 21:33:26'),
(254, '2025-11-06', 'Análisis y revisión', 31, 'Búsqueda y recopilación de información para elaborar el Boletín Regulatorio, correspondiente al mes de octubre de 2025.', 'Horas Internas', 4, 2, 3, 'Completo', 11, 0, 1, 2, NULL, NULL, '2025-11-06 17:49:49', '2025-11-10 21:33:43'),
(255, '2025-11-07', 'Análisis y revisión', 1, 'Proceso de registro de denominación y logo de AMPARA ante INDECOPI', 'Horas Internas', 4, 2, 4, 'Completo', 11, 0, 1, 2, NULL, NULL, '2025-11-06 17:51:56', '2025-11-13 21:39:03'),
(256, '2025-11-30', 'Horas audio', 14, 'audio con Rafael sobre varios temas y encargos de interconexion (6-11-25) (SOCIOS) (40 min) | correos de seguimiento de temas pendientes (10-11-25) (17-11-25) (JROJAS) (30 min) | Elaboración de correo a fin de listar plazos de implementación del mandato de OMV con ENTEL (25-11-25) (JROJAS) (35 min) | ', 'Soporte', 3, 3, 2, 'Completo', 5, 0, 1, 3, '-', '2025-11-28', '2025-11-07 16:50:26', '2025-11-28 19:12:31'),
(257, '2025-11-10', 'Reunión', 33, 'Reunión presencial a fin de revisar estrategias frente al pago de aportes al OSIPTEL', 'Soporte', 3, 3, 3, 'Completo', 3, 0, 1, 3, NULL, NULL, '2025-11-07 16:52:41', '2025-11-11 14:19:22'),
(258, '2025-11-30', 'Horas audio', 1, 'Absolución de consultas de Julio y Giovanna vía llamada y WhatsApp con Juan Carlos y Evelyn sobre cláusula de condición de más favorable en contratos de compartición (7.11.2025) // Absolución de consultas de Julio Cieza con Gustavo y Gino sobre aportes respecto de comercializadores (13.11.2025) // Absolución de consulta de Julio por WhatsApp y llamada telefónica con Gustavo sobre plazos de suspensión, corte y baja del servicio, así como por negativa a contratar (17.11.2025) // Absolución de consulta de Julio por WhatsApp y llamada con Gustavo sobre alcance y vigencia de mandatos de compartición (19.11.2025) // Revisión solicitada por Julio respecto de carta para comunicar negativa a contratar a INTEGRATEL (21.11.2025) // Absolución de consulta operativa de Julio con Gustavo sobre DJ en solicitud de mandato (24.11.2025) // Absolución de consulta de Giovanna vía WhatsApp con Gino sobre permanencia a nivel regulatorio de servicios mayoristas (25.11.2025) // Absolución de consulta de Giovanna sobre aplicabilidad de normativa de proveedor importante en contrato con INTEGRATEL (26.11.2025) // Audio de Julio con Evelyn sobre escenarios y alcances de vigencia de anexos de servicio según contrato WSA (27.11.2025) // Audio de Julio con Evelyn sobre continuidad de Contrato WSA ante procedimiento concursal de INTEGRATEL (27 y 28.11.2025).', 'Soporte', 4, 4, 4, 'Completo', 6, 0, 1, 4, 'pendiente', '2025-11-30', '2025-11-07 18:58:48', '2025-11-28 19:38:35'),
(259, '2025-11-10', 'Análisis y revisión', 7, 'Análisis y revisión de normativa, informes, mandatos, entre otros documentos asociados, a fin de brindar atención a consulta de Julio Cieza sobre alcance real del artículo 6 de Reglamento de Ley N°28295 sobre la obligatoriedad de incluir la cláusula de adecuación de condiciones más favorables en todos los contratos de compartición de infraestructura.', 'Soporte', 4, 4, 3, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-11-07 22:41:47', '2025-11-10 21:57:54'),
(260, '2025-11-12', 'Reunión', 11, 'Reunión solicitada por Pedro Castro y William Blas para absolver consultas derivadas de informe de STARLINK, elaborado por AMPARA; así como también, respecto de solicitud formal enviada por el INPE donde requiere ampliar el alcance de su servicio de bloqueo a las señales de dicha empresa. Se brindaron recomendaciones y posibles acciones a tener en cuenta frente a dicha solicitud. ', 'Soporte', 4, 4, 2, 'Completo', 8, 0, 1, 4, NULL, NULL, '2025-11-07 22:44:56', '2025-11-13 18:11:58'),
(261, '2025-11-10', 'Análisis y revisión', 3, 'Revisión de proyecto de convenio a suscribir con el MINJUS, solicitado por Viviana Sanchez, respecto de los alcances de la cláusula sobre protección de datos personales a utilizarse en el marco de la prestación del servicio de telefonía de uso público en establecimientos penitenciarios. Se efectuaron cambios en el texto y se brindaron algunas recomendaciones.', 'Soporte', 4, 4, 1, 'Completo', 8, 0, 1, 4, NULL, NULL, '2025-11-07 22:49:54', '2025-11-10 21:40:27'),
(262, '2025-11-11', 'Análisis y revisión', 15, 'Elaboración de comentarios a la solicitud de modificación de Mandato de ACCESO realizado por BITEL, respecto a la inclusión de la clausula Antispam.', 'Soporte', 3, 3, 3, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-11-07 23:40:10', '2025-11-11 16:05:43'),
(263, '2025-12-05', 'Análisis y revisión', 14, 'Analisis y revisión para la elaboración de comunicación respecto a la improcedencia de solicitud de un nuevo PDI SIP para la interconexión CLARO-INTERMAX', 'Soporte', 3, 3, 2, 'En proceso', 5, 0, 1, 3, NULL, NULL, '2025-11-10 13:42:52', '2025-11-10 13:42:52'),
(264, '2025-11-21', 'Análisis y revisión', 14, 'Elaboración de comentarios de las 33 observaciones realizadas por CLARO  al proyecto de Mandato para la interconexión de telefonía (SIP)', 'Soporte', 3, 3, 4, 'Completo', 4, 0, 1, 3, NULL, NULL, '2025-11-10 13:44:47', '2025-11-21 20:03:29'),
(265, '2025-11-07', 'Análisis y revisión', 27, 'Revisión del contrato de Arrendamiento de Circuitos con Integratel para el cálculo de las compensaciones por averías. Se elaboró un Excel que calcula el monto a compensar a partir del valor en minutos de la interrupción, tomando en consideración todas las variables establecidas en dicho contrato. Se remitió mediante correo el archivo que valida los montones finales a compensar y algunas recomendaciones adicionales.', 'Soporte', 12, 3, 2, 'Completo', 3, 0, 1, 3, NULL, NULL, '2025-11-10 13:51:08', '2025-11-10 13:51:08'),
(266, '2025-11-30', 'Horas audio', 23, 'Llamada con Kazhia sobre el tema de cartas para inicio de Operaciones y coordinaciones (30 MIN) (JACY) (11/11/25) ||  Audio con William sobre consulta de inicio de operaciones (5 MIN) (GUSTAVO) (26/11/2025) || Coordinación sobre supervisión de inicio de operaciones (10 MIN) (GINO) (28/11/25)', 'Soporte', 12, 12, 1, 'Completo', 9, 0, 1, 12, NULL, '2025-11-28', '2025-11-12 14:32:06', '2025-11-28 19:30:32'),
(267, '2025-11-13', 'Análisis y revisión', 14, 'Reunión con GG del OSIPTEL a fin de evidenciar la conducta anticompetitiva de BITEL frente a la INTERCONEXIÓN y Acceso', 'Soporte', 3, 3, 2, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-11-14 15:27:36', '2025-11-14 15:27:36'),
(268, '2025-11-14', 'Reunión', 14, 'Reunión a fin de evaluar los impactos regulatorios y técnicos de la terminación del mandato FIBERMAX-INTEGRATEL, además de evaluar estrategia de trasladar denuncias a OSIPTEL por la no implementación de la interconexión ENTEL/BITEL. Además INTERMAX presento las evidencias del bloqueo a los mensajes OTP por parte de CLARO. ', 'Soporte', 3, 3, 2, 'Completo', 4, 0, 1, 3, NULL, NULL, '2025-11-14 18:16:53', '2025-11-27 00:01:45'),
(269, '2025-11-18', 'Análisis y revisión', 7, 'Análisis y revisión de normativa para brindar alcances, incluir modificaciones y recomendaciones al proyecto de solicitud de emisión de mandato de compartición de infraestructura eléctrica con SEAL solicitado por Julio Cieza. Asimismo, se señalaron los puntos más importantes a evaluar por OSIPTEL, en base a diversos mandatos publicados en su página web, así como se indicaron algunos riesgos advertidos a nivel formal, de fondo y documentario.', 'Soporte', 4, 4, 4, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-11-15 01:10:31', '2025-11-21 22:08:24'),
(270, '2025-11-21', 'Análisis y revisión', 5, 'Análisis y revisión de normativa de telecomunicaciones, penal y sectorial, así como documentos asociados, para elaborar informe sobre sanciones administrativas y penales por infracciones al secreto de telecomunicaciones, por parte de servidores del Ministerio Público, solicitado por Pedro Castro. Se incluyó análisis sobre alcance de la disociación que PRISONTEC efectuará a los datos de las llamadas que enviará a dicha entidad, como punto fundamental que determina la comisión de infracciones al secreto como también a la protección de datos personales.', 'Soporte', 4, 4, 5, 'Completo', 8, 0, 1, 4, NULL, '2025-11-26', '2025-11-15 01:13:56', '2025-11-27 19:45:52'),
(271, '2025-11-17', 'Análisis y revisión', 33, 'Analisis y elaboración de informe que determina y sustenta la aplicación de la alicuota al servicio de OIMR provisto por IPT', 'Soporte', 3, 3, 6, 'Completo', 3, 0, 1, 3, 'https://1drv.ms/w/c/7a5dfa2a0dc034e8/EXBpBPZ8-v5HpiSpoXdDgMMBW4v-DWcvcAOc3n7BqGY6-A?e=fkiaK5', '2025-11-12', '2025-11-17 13:34:11', '2025-12-01 16:15:08'),
(272, '2025-11-30', 'Horas audio', 1, 'consulta sobre aplicación de ORC en proyecto de modificación de contrato de INTERMAX con Luz Del Sur (17-11-25) (GUSTAVO) (20 min) | Audio y correos con Ernesto respecto a segumiento de temas (17-11-25)(10-11-25) (JROJAS) (35 min)', 'Soporte', 4, 3, 1, 'Completo', 4, 0, 1, 3, '-', '2025-11-28', '2025-11-17 21:25:58', '2025-11-28 19:15:15'),
(273, '2025-11-30', 'Horas audio', 14, 'Llamada con Juan Inga sobre la interconexión con INTEGRATEL (30 MIN) (18/11/25) || Zoom con Javier (20 MIN) (20/11/25) || 5G con BITEL, Interconexión con INTEGRATEL y preciones al Informe de Renovación (20 MIN) (28/11/25)', 'Soporte', 3, 12, 1, 'Completo', 2, 0, 1, 12, '.', '2025-11-28', '2025-11-18 23:01:24', '2025-11-28 19:12:55'),
(274, '2025-11-20', 'Reunión', 1, 'Reunión para la revisión de contrato entre SATELCEL y URBI y la regularización contractual para respaldar el inicio de operaciones.\r\n', 'Soporte', 4, 12, 1, 'Completo', 9, 0, 1, 12, NULL, NULL, '2025-11-21 22:14:29', '2025-11-21 22:29:01'),
(275, '2025-11-24', 'Análisis y revisión', 1, 'Atención de observaciones en expedientes de solicitud de registro de marcas de AMPARA. Se elaboró posible glosa que reemplaza a la indicada en las solicitudes. Asimismo, se elaboraron las cartas de respuesta y también se hicieron consultas telefónicas con INDECOPI.', 'Horas Internas', 4, 2, 2, 'Completo', 11, 0, 1, 2, 'Pendiente', '2025-11-27', '2025-11-21 22:50:01', '2025-11-28 21:11:57'),
(276, '2025-11-28', 'Análisis y revisión', 17, 'Revisión de Orden de Servicio (OS) de URBI con SATELCEL, respecto de su viabilidad como prueba ante inspección de MTC por servicio LDN. Se elaboró glosa del alcance del servicio a incluir en nueva OS a suscribir por PAPSAC con SATELCEL y se brindaron sugerencias a considerar durante su suscripción, considerando solo aspectos de la implementación de enlace satelital.', 'Soporte', 4, 12, 2, 'Completo', 9, 0, 1, 12, NULL, '2025-11-27', '2025-11-21 22:55:00', '2025-11-27 19:12:40'),
(277, '2025-11-26', 'Análisis y revisión', 14, 'Elaboración de carta a fin de brindar nuestros descargos a los comentarios de INTEGRATEL a la solicitud de emisión de Mandato con INTERMAX (como OMV).', 'Soporte', 3, 3, 3, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-11-25 14:00:33', '2025-11-26 22:27:31'),
(278, '2025-11-21', 'Análisis y revisión', 25, 'Envío de propuesta de glosa de facturación, que delimita los montos que serán considerandos para el aporte por regulación y los que no serán considerados. Corrección de llenado de Ficha Técnica de Bandas Libres, donde se consignó la banda de operación 5470 - 5725 MHz, se verificó que el equipamiento (de arquitectura integrada transmisor/antena) cuente con la debida homologación vigente ante el MTC y se ajustaron los parámetros de operación para garantizar el cumplimiento de los límites de potencia de transmisión y el PIRE máximo normativo.', 'Soporte', 12, 12, 2, 'Completo', 9, 0, 1, 12, NULL, NULL, '2025-11-26 14:04:27', '2025-11-26 23:24:32'),
(279, '2025-11-26', 'Reunión', 14, 'Acompañamiento en fiscalización presencial con el MTC la cual tenia como finalidad verificar el cumplimiento del PTFN dentro de la interconexión establecida con CLARO', 'Soporte', 3, 3, 7, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-11-27 20:31:41', '2025-11-27 20:33:25'),
(280, '2025-11-27', 'Reunión', 14, 'Acompañamiento en fiscalización presencial con el MTC la cual tenia como finalidad verificar el cumplimiento del PTFN dentro de la interconexión establecida con INTEGRATEL', 'Soporte', 3, 3, 5, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-11-27 20:32:43', '2025-11-27 20:32:43'),
(281, '2025-11-24', 'Reunión', 14, 'Reunión con el equipo INTERMAX  a fin de determinar estrategia para las fiscalizaciones que llevara a cabo el MTC, se realizó revisión del requerimiento de información y ademas se alinearon criterios regulatorios respecto a la numeración de los SMS ageográficos OTT', 'Soporte', 3, 3, 2, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-11-27 20:36:55', '2025-11-27 20:36:55'),
(282, '2025-11-27', 'Análisis y revisión', 7, 'Análisis y revisión normativa, informes y documentos asociados para determinar el régimen aplicable a su contrato de compartición con INTEGRATEL considerando que, actualmente, dicha empresa dejó de ser Proveedor Importante en mercados mayoristas de infraestructura.', 'Soporte', 4, 4, 2, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-11-27 20:58:16', '2025-11-27 20:58:16'),
(283, '2025-11-27', 'Análisis y revisión', 17, 'Análisis y revisión de escenarios planteados por el clientes para determinar el momento de inicio de vigencia de los Anexos de Servicio, de acuerdo con lo establecido en el Contrato WSA, celebrado entre INTEGRATEL y PANGEACO.', 'Soporte', 4, 4, 2, 'Completo', 6, 0, 1, 4, NULL, NULL, '2025-11-27 21:26:52', '2025-11-27 21:26:52'),
(284, '2025-11-27', 'Análisis y revisión', 17, 'Análisis y revisión de contratos de concesión y demás títulos habilitantes de INTEGRATEL, así como de normativa sectorial y regulatoria para proyectar los posibles impactos de su procedimiento concursal y actual situación financiera en el Contrato WSA, solicitado por Julio Cieza. Se elaboró correo detallando el análisis por cada aspecto revisado y señalando los puntos que se sugiere considerar por parte del cliente.', 'Soporte', 4, 4, 4, 'Completo', 6, 0, 1, 4, 'pendiente', '2025-11-27', '2025-11-28 16:56:34', '2025-11-28 16:56:34'),
(285, '2025-11-30', 'Análisis y revisión', 4, 'Revisión e identificación de normas de telecomunicaciones en el diario oficial El Peruano, página oficial de OSIPTEL y agendas para sesiones de Consejo Directivo para realizar actualización de Alerta Normativa durante el mes de noviembre. Adecuación de la plantilla y envío a contactos.', 'Horas Internas', 4, 2, 3, 'Completo', 11, 0, 1, 4, 'pendiente', '2025-11-30', '2025-11-28 17:00:34', '2025-11-28 17:00:34'),
(286, '2025-11-27', 'Análisis y revisión', 14, 'Coordinación con INTEGRATEL y equipo técnico de DOLPHIN  a fin de establecer el impago de la coubicación de equipos por la implementación de enlaces de interconexión, Se coordino con Juan Inga a fin de que viabilizar el tema y el impago de la coubicación.', 'Soporte', 3, 12, 3, 'Completo', 2, 0, 1, 3, 'ASUNTO_CORREO:RV: REMISION ORDEN SERVICIO INTERCONEXION INTEGRATEL & DOLPHIN', '2025-11-27', '2025-11-28 17:54:58', '2025-11-28 17:54:58'),
(287, '2025-11-28', 'Reunión', 16, 'Reunión con IPT a fin de viabilizar el nuevo modelo de negocio con ENTEL; ademas se comentaron temas respecto a los aportes por regulación del OSIPTEL', 'Soporte', 4, 3, 1, 'Completo', 3, 0, 1, 3, 'https://teams.microsoft.com/l/meetup-join/19%3ameeting_MmYxMjVlM2ItZTJkNS00MTAyLWJjOTUtMjA4OGI0YWUxODM4%40thread.v2/0?context=%7b%22Tid%22%3a%2292484b96-ad23-48aa-b534-e36a56a7eafd%22%2c%22Oid%22%3a%22f1378d0f-cc6d-4202-8b31-79e311dcac49%22%7d', '2025-11-28', '2025-11-28 17:58:00', '2025-11-28 17:58:00'),
(288, '2025-11-18', 'Análisis y revisión', 14, 'Elaboración de carta a GG a fin de trasladar la PPT presentada en reunión respecto a los incumplimientos de BITEL', 'Soporte', 3, 3, 2, 'Completo', 5, 0, 1, 3, '-', '2025-11-18', '2025-11-28 20:05:57', '2025-11-28 20:05:57'),
(289, '2025-11-24', 'Análisis y revisión', 1, 'Elaboración de Carta para denuncia penal a BITEL', 'Soporte', 4, 3, 2, 'Completo', 5, 0, 1, 3, '-', '2025-11-24', '2025-11-28 20:07:04', '2025-11-28 20:07:04'),
(290, '2025-11-28', 'Análisis y revisión', 14, 'Elaboración de carta a fin de brindar respuesta al requerimiento de OSIPTEL respecto de los SMS de FIBERMAX. En la medida que las interconexiones con los operadores móviles se encuentran en implementación el reporte se remite en 0.', 'Soporte', 3, 3, 2, 'Completo', 4, 0, 1, 3, 'https://1drv.ms/u/c/8273a3182564d1ab/IQBeqxO_byIMR4cxJQG3z_EiAX0ZXpJUs07adxIIWFUb78c?e=2WDTit', '2025-11-28', '2025-11-28 23:17:36', '2025-11-28 23:17:36'),
(291, '2025-11-26', 'Análisis y revisión', 14, 'Elaboración de PPT a fin de exponer bloqueo de interconexión por parte de CLARO', 'Soporte', 3, 3, 1, 'Completo', 5, 0, 1, 3, NULL, NULL, '2025-12-01 16:13:54', '2025-12-01 16:13:54'),
(292, '2025-12-31', 'Horas audio', 14, 'audio con Rafael y Marcelo respecto a la postergación de fiscalización del MTC con Integratel (1-12-25) (SOCIOS) (30 min) | Elaboración de correo a fin de dar seguimiento a la implementación del OMV con ENTEL y trasladar el sustento de los cargos aplicables (1-12-25) (JROJAS) (30 min) | ', 'Soporte', 3, 3, 2, 'En proceso', 5, 0, 1, 3, NULL, NULL, '2025-12-01 19:27:44', '2025-12-01 20:54:23'),
(293, '2025-12-02', 'Reunión', 14, 'Reunión a fin de comentar estrategia frente a la terminación de mandato FIBERMAX-INTEGRATEL', 'Soporte', 3, 3, 1, 'Completo', 4, 0, 1, 3, '-', '2025-12-02', '2025-12-01 19:37:53', '2025-12-02 19:16:18'),
(294, '2025-12-02', 'Análisis y revisión', 14, 'Elaboración de Informe que permita evidenciar estrategia frente a la terminación del mandato de interconexión entre FIBERMAX e INTEGRATEL', 'Soporte', 3, 3, 4, 'Completo', 4, 0, 1, 3, 'https://1drv.ms/u/c/8273a3182564d1ab/IQCcKwbgJzo5RJhOf8RyGf2eAWx52XLIYY0w4kYEsrkyHKI?e=UaMO43', '2025-12-03', '2025-12-01 20:45:14', '2025-12-04 00:45:03'),
(295, '2025-12-04', 'Análisis y revisión', 14, 'Elaboración de carta que permita evidenciar la negativa frente a la terminación del mandato de interconexión entre FIBERMAX e INTEGRATEL', 'Soporte', 3, 3, 2, 'En proceso', 4, 0, 1, 3, NULL, NULL, '2025-12-01 20:45:52', '2025-12-01 20:45:52'),
(296, '2025-12-03', 'Análisis y revisión', 14, 'Elaboración de carta a fin de dar respuesta a requerimiento planteado por CCO del OSIPTEL respecto al servicio de SMS A2P alfanumerico', 'No Soporte', 3, 3, 3, 'Completo', 10, 0, 1, 3, 'https://1drv.ms/u/c/8273a3182564d1ab/IQAd_x8bPQ3fRbsJyX304efnAaVhDxPZs5XigbZiP29Lyy8?e=NpFDGh', '2025-12-02', '2025-12-01 20:47:23', '2025-12-03 23:05:17'),
(297, '2025-12-03', 'Análisis y revisión', 14, 'Elaboración de comunicación a fin de brindar respuesta al requerimiento de información a DPRC respecto al mercado de SMS de INTERMAX y monetizadores', 'Soporte', 3, 3, 3, 'Completo', 5, 0, 1, 3, 'https://1drv.ms/u/c/8273a3182564d1ab/IQAMo-gV8v1CSogHQGJPvutfAVf5hLchSWBVm8i0ecQ-Q_M?e=MLnpvn', '2025-12-03', '2025-12-01 20:48:32', '2025-12-03 23:14:06'),
(298, '2025-12-04', 'Análisis y revisión', 2, 'Agenda regulatoria del mes de DICIEMBRE de 2025', 'Horas Internas', 12, 2, 3, 'En proceso', 11, 0, 1, 3, NULL, NULL, '2025-12-01 20:49:34', '2025-12-01 20:49:34'),
(299, '2025-12-05', 'Análisis y revisión', 25, 'Elaboración de carta a DIRECIÓN GENERAL del MTC a fin de reiterar la solicitud de asignación de  numeración del servicio de telefonía fija.', 'Soporte', 12, 3, 2, 'En proceso', 5, 0, 1, 3, NULL, NULL, '2025-12-01 20:51:10', '2025-12-01 20:51:10'),
(300, '2025-12-04', 'Análisis y revisión', 14, 'Elaboración de carta a fin de brindar comentarios a los descargos realizados por BITEL a la modificación de la clausula antispam', 'Soporte', 3, 3, 1, 'Completo', 5, 0, 1, 3, 'https://1drv.ms/u/c/8273a3182564d1ab/IQBKI6sS_IRzSpcSfkhH92__ATIkNH8J79RBjUFixW3sMfE?e=Pl3r9S', '2025-12-04', '2025-12-01 20:52:55', '2025-12-04 14:17:39'),
(301, '2025-12-12', 'Análisis y revisión', 15, 'Respuesta al requerimiento de información por parte de OSIPTEL respecto a los servicios prestados como OMV y estado de las implementaciones', 'Soporte', 3, 3, 3, 'En proceso', 5, 0, 1, 3, NULL, NULL, '2025-12-01 20:55:39', '2025-12-01 20:55:39'),
(302, '2025-12-31', 'Horas audio', 14, 'Coordinaciones respecto a la estrategia por el impago de la coubicación de equipos (5 MIN)(JACY)(02/12) ||', 'Soporte', 3, 12, 1, 'En proceso', 2, 0, 1, 12, NULL, NULL, '2025-12-02 19:00:06', '2025-12-02 19:00:06'),
(303, '2025-12-31', 'Horas audio', 25, 'Reportes periódicos para el SIGIEP-MTC (30 MIN)(JACY)(02/12) ||', 'Soporte', 12, 12, 1, 'En proceso', 9, 0, 1, 12, NULL, NULL, '2025-12-02 19:01:21', '2025-12-02 19:01:21'),
(304, '2025-12-31', 'Horas audio', 1, 'Absolución de consultas de Giovanna vía llamada y WhatsApp con Evelyn sobre nueva metodología de aplicación de suspensión de servicio (2.12.2025) // Absolución de consultas adicionales de Julio vía llamada con Evelyn sobre suspensión de servicio y negativa a contratar (3.12.2025)', 'Soporte', 4, 4, 1, 'En proceso', 6, 0, 1, 4, NULL, NULL, '2025-12-04 16:28:02', '2025-12-04 16:31:09'),
(305, '2025-12-03', 'Análisis y revisión', 6, 'Elaboración de presentación didáctica (ppt) respecto del tema \"Regulación diferenciada entre usuarios: Abonado Corporativo”. Exposición de dicho tema ante el equipo AMPARA.', 'Soporte', 4, 2, 3, 'Completo', 11, 0, 1, 4, 'pendiente', '2025-12-03', '2025-12-04 17:04:48', '2025-12-04 17:04:48'),
(306, '2025-12-02', 'Análisis y revisión', 17, 'Revisión y atención de comentarios adicionales de Kazhia F. a Orden de Servicio (OS) de URBI con SATELCEL, así como de comentarios al proyecto de Acta de Instalación derivada de la misma. Se remitió modelos en línea para complementar dicha acta, conteniendo el detalle de posible protocolo de pruebas. Asimismo, se absolvieron consultas de Kazhia F. sobre estrategia de fechas, publicación de tarifas y otros, en torno al inicio de operaciones sobre LDN y PL, en contraste con el inicio de operaciones de LDI; para lo cual se preparó un flujo de tiempo en formato Excel que se envió al cliente.', 'Soporte', 4, 12, 3, 'Completo', 9, 0, 1, 12, '.', '2025-12-02', '2025-12-04 17:21:19', '2025-12-04 17:21:19'),
(307, '2025-12-01', 'Análisis y revisión', 25, 'Se revisó la Carta de Conclusiones Previas de la Fiscalización Aportes 2022 notificada por OSIPTEL, analizando el reparo respecto a la deducción indebida de Notas de Crédito del periodo 2021 y si se podrían considerar parte del periodo 2022. Asimismo, se determinó la cuantía de la sanción y la viabilidad del acogimiento al Régimen de Incentivos (rebaja del 70%), emitiendo una recomendación estratégica que pondera el beneficio económico inmediato frente al impacto que generaría el pago como reconocimiento tácito de la infracción. Adicionalmente, se analizaron los plazos para el reclamo de declaración del periodo 2021.', 'Soporte', 12, 12, 2, 'Completo', 3, 0, 1, 12, '.', '2025-12-01', '2025-12-04 17:31:26', '2025-12-04 17:31:26'),
(308, '2025-12-02', 'Reunión', 17, 'Reunión para la preparación sobre la fiscalización del inicio de operaciones de sus servicios Portador LDN y Portador Local y absolución las consultas sobre las fechas de los contratos y OS entre PAPSAC y SATELCEL.', 'Soporte', 4, 12, 1, 'Completo', 9, 0, 1, 12, '.', '2025-12-02', '2025-12-04 17:37:22', '2025-12-04 17:37:22');

--
-- Disparadores `liquidacion`
--
DELIMITER $$
CREATE TRIGGER `trg_after_liquidacion_insert` AFTER INSERT ON `liquidacion` FOR EACH ROW BEGIN
    DECLARE v_idplanificacion INT DEFAULT NULL;
    DECLARE v_iddetalle_inserted INT DEFAULT NULL;
    DECLARE v_dist_hora_count INT DEFAULT 0;

    INSERT INTO trigger_debug_log (trigger_name, message, idliquidacion_val, estado_val)
    VALUES ('insert', 'Trigger START', NEW.idliquidacion, NEW.estado);

    SELECT Idplanificacion INTO v_idplanificacion
    FROM planificacion
    WHERE idContratoCliente = NEW.idcontratocli
      AND YEAR(fechaplan) = YEAR(NEW.fecha)
      AND MONTH(fechaplan) = MONTH(NEW.fecha)
    LIMIT 1;

    INSERT INTO trigger_debug_log (trigger_name, message, idliquidacion_val, planificacion_id_val)
    VALUES ('insert', 'After Planificacion SELECT', NEW.idliquidacion, v_idplanificacion);

    IF v_idplanificacion IS NOT NULL THEN
        INSERT INTO `detalles_planificacion` (
            `Idplanificacion`, `idliquidacion`, `fechaliquidacion`, `estado`, `cantidahoras`
        ) VALUES (
            v_idplanificacion, NEW.idliquidacion, NEW.fecha, NEW.estado, NEW.cantidahoras
        );
        SET v_iddetalle_inserted = LAST_INSERT_ID();
        INSERT INTO trigger_debug_log (trigger_name, message, idliquidacion_val, iddetalle_val, estado_val)
        VALUES ('insert', 'After detalles_planificacion INSERT', NEW.idliquidacion, v_iddetalle_inserted, NEW.estado);

        IF v_iddetalle_inserted IS NOT NULL AND TRIM(UPPER(NEW.estado)) = 'COMPLETO' THEN
            INSERT INTO trigger_debug_log (trigger_name, message, idliquidacion_val, iddetalle_val, estado_val, insert_attempted)
            VALUES ('insert', 'CONDITION MET for distrib_planif', NEW.idliquidacion, v_iddetalle_inserted, NEW.estado, FALSE);

            SELECT COUNT(*) INTO v_dist_hora_count
            FROM `distribucionhora` dh
            WHERE dh.idliquidacion = NEW.idliquidacion;

            INSERT INTO trigger_debug_log (trigger_name, message, idliquidacion_val, distribucionhora_count)
            VALUES ('insert', 'Count from distribucionhora', NEW.idliquidacion, v_dist_hora_count);

            IF v_dist_hora_count > 0 THEN
                DELETE FROM `distribucion_planificacion` WHERE `iddetalle` = v_iddetalle_inserted;
                INSERT INTO trigger_debug_log (trigger_name, message, idliquidacion_val, iddetalle_val)
                VALUES ('insert', 'After DELETE from distrib_planif', NEW.idliquidacion, v_iddetalle_inserted);

                INSERT INTO `distribucion_planificacion` (
                    `iddetalle`, `idparticipante`, `porcentaje`, `horas_asignadas`
                )
                SELECT
                    v_iddetalle_inserted,
                    dh.participante,
                    dh.porcentaje,
                    COALESCE(dh.calculo, 0.00) -- Usar COALESCE como medida defensiva
                FROM `distribucionhora` dh
                WHERE dh.idliquidacion = NEW.idliquidacion;

                INSERT INTO trigger_debug_log (trigger_name, message, idliquidacion_val, iddetalle_val, insert_attempted)
                VALUES ('insert', 'After INSERT attempt to distrib_planif', NEW.idliquidacion, v_iddetalle_inserted, TRUE);
            ELSE
                INSERT INTO trigger_debug_log (trigger_name, message, idliquidacion_val, distribucionhora_count, insert_attempted)
                VALUES ('insert', 'Skipped INSERT (no rows in distribucionhora)', NEW.idliquidacion, v_dist_hora_count, FALSE);
            END IF;
        ELSE
            INSERT INTO trigger_debug_log (trigger_name, message, idliquidacion_val, iddetalle_val, estado_val, insert_attempted)
            VALUES ('insert', 'CONDITION NOT MET for distrib_planif', NEW.idliquidacion, v_iddetalle_inserted, NEW.estado, FALSE);
        END IF;
    ELSE
        INSERT INTO trigger_debug_log (trigger_name, message, idliquidacion_val, planificacion_id_val, insert_attempted)
        VALUES ('insert', 'v_idplanificacion IS NULL', NEW.idliquidacion, v_idplanificacion, FALSE);
    END IF;
    INSERT INTO trigger_debug_log (trigger_name, message, idliquidacion_val)
    VALUES ('insert', 'Trigger END', NEW.idliquidacion);
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_after_liquidacion_update` AFTER UPDATE ON `liquidacion` FOR EACH ROW BEGIN
    DECLARE v_iddetalle INT DEFAULT NULL;
    DECLARE v_idplanif_for_insert INT DEFAULT NULL;

    SELECT dp.iddetalle INTO v_iddetalle
    FROM detalles_planificacion dp
    WHERE dp.idliquidacion = NEW.idliquidacion
    LIMIT 1;

    IF v_iddetalle IS NOT NULL THEN
        UPDATE `detalles_planificacion`
        SET
            `fechaliquidacion` = NEW.fecha,
            `estado` = NEW.estado,
            `cantidahoras` = NEW.cantidahoras,
            `modificado` = CURRENT_TIMESTAMP
        WHERE `iddetalle` = v_iddetalle;
    ELSE 
        SELECT p.Idplanificacion INTO v_idplanif_for_insert
        FROM planificacion p
        WHERE p.idContratoCliente = NEW.idcontratocli
          AND YEAR(p.fechaplan) = YEAR(NEW.fecha)
          AND MONTH(p.fechaplan) = MONTH(NEW.fecha)
        LIMIT 1;

        IF v_idplanif_for_insert IS NOT NULL THEN
            INSERT INTO `detalles_planificacion` (
                `Idplanificacion`,
                `idliquidacion`,
                `fechaliquidacion`,
                `estado`,
                `cantidahoras`
            ) VALUES (
                v_idplanif_for_insert,
                NEW.idliquidacion,
                NEW.fecha,
                NEW.estado,
                NEW.cantidahoras
            );
            SET v_iddetalle = LAST_INSERT_ID(); 
        END IF;
    END IF;

    IF v_iddetalle IS NOT NULL AND TRIM(UPPER(NEW.estado)) = 'COMPLETO' THEN
        DELETE FROM `distribucion_planificacion` WHERE `iddetalle` = v_iddetalle;
        
        INSERT INTO `distribucion_planificacion` (
            `iddetalle`,
            `idparticipante`,
            `porcentaje`,
            `horas_asignadas`
        )
        SELECT
            v_iddetalle,
            dh.participante,
            dh.porcentaje,
            dh.calculo 
        FROM `distribucionhora` dh
        WHERE dh.idliquidacion = NEW.idliquidacion;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planificacion`
--

CREATE TABLE `planificacion` (
  `Idplanificacion` int(11) NOT NULL,
  `idContratoCliente` int(11) NOT NULL,
  `nombreplan` varchar(255) NOT NULL,
  `fechaplan` date NOT NULL,
  `horasplan` int(11) NOT NULL,
  `lider` int(11) NOT NULL,
  `comentario` text DEFAULT NULL,
  `activo` int(11) NOT NULL DEFAULT 1,
  `editor` int(11) NOT NULL,
  `registrado` timestamp NOT NULL DEFAULT current_timestamp(),
  `modificado` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `planificacion`
--

INSERT INTO `planificacion` (`Idplanificacion`, `idContratoCliente`, `nombreplan`, `fechaplan`, `horasplan`, `lider`, `comentario`, `activo`, `editor`, `registrado`, `modificado`) VALUES
(1, 1, 'Plan Mensual CALA -Mayo 2025', '2025-05-01', 10, 4, 'Plan Mensual CALA -Mayo 2025', 1, 2, '2025-07-17 18:29:55', '2025-07-25 18:04:09'),
(2, 5, 'Plan Mensual INTERMAX - Mayo 2025', '2025-05-01', 24, 3, 'Plan Mensual INTERMAX - Mayo', 1, 2, '2025-07-17 23:46:09', '2025-07-25 18:03:54'),
(3, 4, 'Plan Mensual FIBERMAX - Mayo 2025', '2025-05-01', 10, 6, 'Plan Mensual FIBERMAX - Mayo', 1, 2, '2025-07-18 01:19:16', '2025-07-25 18:03:38'),
(4, 2, 'Plan Mensual DOLPHIN - Mayo 2025', '2025-05-01', 10, 6, 'Plan Mensual DOLPHIN - Mayo', 1, 2, '2025-07-18 01:23:38', '2025-07-25 18:03:17'),
(5, 6, 'Plan Mensual PANGEACO - Julio 2025', '2025-07-01', 18, 4, 'Plan Mensual PANGEACO - Mayo 2025', 1, 2, '2025-07-18 01:31:36', '2025-07-25 18:02:00'),
(6, 1, 'Plan Mensual CALA - Julio 2025', '2025-07-01', 10, 4, 'Plan Mensual CALA - Julio 2025', 1, 2, '2025-07-18 01:39:44', '2025-07-25 18:01:46'),
(7, 8, 'Plan Mensual PRISONTEC - Julio 2025', '2025-07-01', 10, 4, 'Plan Mensual PRISONTEC - Julio 2025', 1, 2, '2025-07-18 01:45:28', '2025-07-25 18:01:32'),
(8, 4, 'Plan Mensual FIBERMAX - Julio 2025', '2025-07-01', 10, 6, 'Plan Mensual FIBERMAX - Julio 2025', 1, 2, '2025-07-18 01:55:12', '2025-07-25 18:01:18'),
(9, 10, 'Plan Mensual INTERMAX - NS - Julio 2025', '2025-06-01', 3, 6, 'Plan Mensual INTERMAX - NS - Julio 2025', 1, 2, '2025-07-18 02:00:13', '2025-07-30 22:01:22'),
(10, 5, 'Plan Mensual INTERMAX - Julio 2025', '2025-07-01', 24, 3, 'Plan Mensual INTERMAX - Julio 2025', 1, 2, '2025-07-18 02:05:20', '2025-07-25 18:01:04'),
(11, 3, 'Plan Mensual IPT - Julio 2025', '2025-07-01', 18, 6, 'Plan Mensual IPT - Julio 2025', 1, 2, '2025-07-18 02:16:17', '2025-07-25 18:00:21'),
(12, 2, 'Plan Mensual DOLPHIN - Julio 2025', '2025-07-01', 10, 6, 'Plan Mensual DOLPHIN - Julio 2025', 1, 2, '2025-07-18 02:19:30', '2025-07-25 18:00:07'),
(13, 11, 'Plan Mensual AMPARA - Julio 2025', '2025-06-01', 10, 2, 'Plan Mensual AMPARA - Julio 2025', 1, 2, '2025-07-18 02:20:21', '2025-07-30 22:01:32'),
(14, 9, 'Plan Mensual PUNTO DE ACCESO - Julio 2025', '2025-07-01', 10, 3, 'Plan Mensual PUNTO DE ACCESO - Julio 2025', 1, 11, '2025-07-23 00:49:05', '2025-07-23 00:49:05'),
(15, 11, 'Plan Mensual AMPARA Agosto 25', '2025-08-01', 7, 2, 'Plan Mensual AMPARA Agosto 25', 1, 2, '2025-08-08 16:18:50', '2025-08-13 15:21:43'),
(16, 5, 'Plan Mensual INTERMAX - Agosto 2025', '2025-08-01', 24, 3, NULL, 1, 2, '2025-08-13 15:17:23', '2025-08-13 15:17:23'),
(17, 6, 'Plan Mensual PANGEACO - Agosto 2025', '2025-08-01', 18, 4, NULL, 1, 2, '2025-08-13 15:17:51', '2025-08-13 15:17:51'),
(18, 3, 'Plan Mensual IPT - Agosto 2025', '2025-08-01', 18, 6, NULL, 1, 2, '2025-08-13 15:18:28', '2025-08-13 15:18:28'),
(19, 4, 'Plan Mensual FIBERMAX - Agosto 2025', '2025-08-01', 10, 3, NULL, 1, 2, '2025-08-13 15:18:52', '2025-08-13 15:18:52'),
(20, 9, 'Plan Mensual Punto de Acceso - Agosto 2025', '2025-08-01', 14, 6, NULL, 1, 2, '2025-08-13 15:19:34', '2025-08-13 15:19:34'),
(21, 8, 'Plan Mensual PRISONTEC - Agosto 2025', '2025-08-01', 10, 4, NULL, 1, 2, '2025-08-13 15:20:00', '2025-08-13 15:20:00'),
(22, 2, 'Plan Mensual DOLPHIN - Agosto 2025', '2025-08-01', 10, 6, NULL, 1, 2, '2025-08-13 15:20:43', '2025-08-13 15:20:43'),
(23, 10, 'Plan Mensual INTERMAX - NS - Agosto 2025', '2025-08-01', 4, 6, NULL, 1, 2, '2025-08-13 15:22:06', '2025-08-13 15:22:06'),
(24, 2, 'Plan Mensual DOLPHIN - Set 25', '2025-09-01', 12, 3, NULL, 1, 2, '2025-09-25 18:59:33', '2025-09-25 18:59:33'),
(25, 4, 'Plan Mensual FIBERMAX - Set 25', '2025-09-01', 12, 3, NULL, 1, 2, '2025-09-25 19:00:05', '2025-09-25 19:00:05'),
(26, 5, 'Plan Mensual INTERMAX - Set 25', '2025-09-01', 24, 3, NULL, 1, 2, '2025-09-25 19:00:33', '2025-09-25 19:00:33'),
(27, 3, 'Plan Mensual IPT - Set 25', '2025-09-01', 18, 3, NULL, 1, 2, '2025-09-25 19:01:08', '2025-09-25 19:01:08'),
(28, 6, 'Plan Mensual PANGEACO - Set 25', '2025-09-01', 18, 4, NULL, 1, 2, '2025-09-25 19:01:42', '2025-09-25 19:01:42'),
(29, 8, 'Plan Mensual PRISONTEC - Set 25', '2025-09-01', 12, 4, NULL, 1, 2, '2025-09-25 21:07:36', '2025-09-25 21:07:36'),
(30, 9, 'Plan Mensual Punto de Acceso - Set 25', '2025-09-01', 6, 4, NULL, 1, 2, '2025-09-25 21:08:37', '2025-09-25 21:08:37'),
(31, 11, 'Plan Mensual AMPARA - Set 25', '2025-09-01', 8, 2, NULL, 1, 2, '2025-09-25 21:10:24', '2025-09-25 21:10:24'),
(32, 11, 'Plan Mensual AMPARA - Octubre 2025', '2025-10-01', 10, 2, NULL, 1, 2, '2025-11-21 21:24:06', '2025-11-21 21:24:06'),
(33, 2, 'Plan Mensual DOLPHIN - Octubre 2025', '2025-10-01', 12, 12, NULL, 1, 2, '2025-11-21 21:24:37', '2025-11-21 21:24:37'),
(34, 4, 'Plan Mensual FIBERMAX - Octubre 2025', '2025-10-01', 12, 3, NULL, 1, 2, '2025-11-21 21:25:03', '2025-11-21 21:25:03'),
(35, 5, 'Plan Mensual INTERMAX - Octubre 2025', '2025-10-01', 24, 3, NULL, 1, 2, '2025-11-21 21:25:34', '2025-11-21 21:25:34'),
(36, 3, 'Plan Mensual IPT - Octubre 2025', '2025-10-01', 18, 3, NULL, 1, 2, '2025-11-21 21:26:02', '2025-11-21 21:26:02'),
(37, 6, 'Plan Mensual PANGEACO - Octubre 2025', '2025-10-01', 18, 4, NULL, 1, 2, '2025-11-21 21:26:28', '2025-11-21 21:26:28'),
(38, 8, 'Plan Mensual PRISONTEC - Octubre 2025', '2025-10-01', 12, 4, NULL, 1, 2, '2025-11-21 21:26:49', '2025-11-21 21:26:49'),
(39, 9, 'Plan Mensual Punto de Acceso - Octubre 2025', '2025-10-01', 6, 12, NULL, 1, 2, '2025-11-21 21:27:12', '2025-11-21 21:27:12'),
(40, 11, 'Plan Mensual AMPARA - Noviembre 2025', '2025-11-01', 10, 2, NULL, 1, 2, '2025-11-21 21:27:43', '2025-11-21 21:32:15'),
(41, 2, 'Plan Mensual DOLPHIN - Noviembre 2025', '2025-11-01', 12, 12, NULL, 1, 2, '2025-11-21 21:28:04', '2025-11-21 21:28:04'),
(42, 4, 'Plan Mensual FIBERMAX - Noviembre 2025', '2025-11-01', 12, 3, NULL, 1, 2, '2025-11-21 21:28:25', '2025-11-21 21:28:25'),
(43, 5, 'Plan Mensual INTERMAX - Noviembre 2025', '2025-11-01', 24, 3, NULL, 1, 2, '2025-11-21 21:28:47', '2025-11-21 21:28:47'),
(44, 3, 'Plan Mensual IPT - Noviembre 2025', '2025-11-01', 18, 3, NULL, 1, 2, '2025-11-21 21:29:13', '2025-11-21 21:29:13'),
(45, 6, 'Plan Mensual PANGEACO - Noviembre 2025', '2025-11-01', 18, 4, NULL, 1, 2, '2025-11-21 21:29:36', '2025-11-21 21:29:36'),
(46, 8, 'Plan Mensual PRISONTEC - Noviembre 2025', '2025-11-01', 12, 4, NULL, 1, 2, '2025-11-21 21:30:21', '2025-11-21 21:30:21'),
(47, 9, 'Plan Mensual Punto de Acceso - Noviembre 25', '2025-11-01', 6, 12, NULL, 1, 2, '2025-11-21 21:30:40', '2025-11-21 21:30:40'),
(48, 11, 'Plan Mensual AMPARA - Diciembre 2025', '2025-12-01', 13, 2, NULL, 1, 2, '2025-11-21 21:32:44', '2025-11-28 19:55:33'),
(49, 2, 'Plan Mensual DOLPHIN - Diciembre 2025', '2025-12-01', 12, 12, NULL, 1, 2, '2025-11-21 21:33:09', '2025-11-21 21:33:09'),
(50, 4, 'Plan Mensual FIBERMAX - Diciembre 2025', '2025-12-01', 12, 3, NULL, 1, 2, '2025-11-21 21:33:33', '2025-11-21 21:33:33'),
(51, 5, 'Plan Mensual INTERMAX - Diciembre 2025', '2025-12-01', 24, 3, NULL, 1, 2, '2025-11-21 21:36:09', '2025-11-21 21:36:09'),
(52, 3, 'Plan Mensual IPT - Diciembre 2025', '2025-12-01', 18, 3, NULL, 1, 2, '2025-11-21 21:36:35', '2025-11-21 21:36:35'),
(53, 6, 'Plan Mensual PANGEACO - Diciembre 2025', '2025-12-01', 18, 4, NULL, 1, 2, '2025-11-21 21:37:03', '2025-11-21 21:37:03'),
(54, 8, 'Plan Mensual PRISONTEC - Diciembre 2025', '2025-12-01', 12, 4, NULL, 1, 2, '2025-11-21 21:37:27', '2025-11-21 21:37:27'),
(55, 9, 'Plan Mensual Punto de Acceso - Diciembre 2025', '2025-12-01', 6, 12, NULL, 1, 2, '2025-11-21 21:37:50', '2025-11-21 21:37:50');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `presupuestocliente`
--

CREATE TABLE `presupuestocliente` (
  `idpresupuesto` int(11) NOT NULL,
  `descripcion` varchar(500) NOT NULL,
  `fechainicio` date NOT NULL,
  `fechafin` date NOT NULL,
  `monto` decimal(7,2) NOT NULL,
  `activo` int(11) NOT NULL,
  `idcliente` int(11) NOT NULL,
  `acargode` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `sesiones_log`
--

CREATE TABLE `sesiones_log` (
  `id` int(11) NOT NULL,
  `idusuario` int(11) NOT NULL,
  `session_php_id` varchar(255) DEFAULT NULL,
  `timestamp_inicio` timestamp NOT NULL DEFAULT current_timestamp(),
  `timestamp_fin` timestamp NULL DEFAULT NULL,
  `duracion_segundos` int(11) DEFAULT NULL,
  `ip_address_inicio` varchar(45) DEFAULT NULL,
  `ip_address_fin` varchar(45) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `sesiones_log`
--

INSERT INTO `sesiones_log` (`id`, `idusuario`, `session_php_id`, `timestamp_inicio`, `timestamp_fin`, `duracion_segundos`, `ip_address_inicio`, `ip_address_fin`) VALUES
(1, 3, 'nat18p1d0aqqjjrsa91i7edtbu', '2025-07-02 20:22:20', '2025-07-03 18:26:09', 79429, '181.176.210.66', '200.121.25.166'),
(2, 3, 'jckal0g5ofg7hhq67tidpasa49', '2025-07-02 20:23:14', '2025-07-03 18:26:09', 79429, '181.176.210.66', '200.121.25.166'),
(3, 3, '107mmq8aogegg5nitjsc4mn3n4', '2025-07-02 21:27:28', '2025-07-03 18:26:09', 79429, '181.176.210.66', '200.121.25.166'),
(4, 4, 'cfis47jq15sfj8vjbtmp0c4q62', '2025-07-02 21:50:19', '2025-07-03 18:26:09', 79429, '181.176.210.66', '200.121.25.166'),
(5, 4, 'c7k19g02414ig16h88lk8g1nfg', '2025-07-02 21:51:30', '2025-07-03 18:26:09', 79429, '181.176.210.66', '200.121.25.166'),
(6, 4, '9doo1kagujph1nq0km7vsk0tqa', '2025-07-02 22:42:16', '2025-07-03 18:26:09', 79429, '181.176.210.66', '200.121.25.166'),
(7, 3, 'ho1huunfgqrr58omjc3505guvo', '2025-07-02 23:17:15', '2025-07-03 18:26:09', 79429, '38.25.18.25', '200.121.25.166'),
(8, 5, 'fqfunc89f2vp8qdkdtlnl0cale', '2025-07-03 01:33:32', '2025-07-03 18:26:09', 79429, '2803:a3e0:1737:7820:d1e0:2862:d5b4:3091', '200.121.25.166'),
(9, 5, 'egcp50aiqummno15pnr5th7s99', '2025-07-03 01:38:06', '2025-07-03 18:26:09', 79429, '2803:a3e0:1737:7820:d1e0:2862:d5b4:3091', '200.121.25.166'),
(10, 3, '63nhdmlklhilkj7pigpt9as7p6', '2025-07-03 10:49:43', '2025-07-03 18:26:09', 79429, '38.25.18.25', '200.121.25.166'),
(11, 3, 'ieg5mtsu2pse3c5389dpj64426', '2025-07-03 15:39:33', '2025-07-03 18:26:09', 79429, '200.121.25.166', '200.121.25.166'),
(12, 6, 'dleqfnck0v22dhhb87s11eliqr', '2025-07-03 17:08:34', '2025-07-03 18:26:09', 79429, '38.25.53.141', '200.121.25.166'),
(13, 3, '099pf09pe2tbtct1qqqlfol3tg', '2025-07-03 18:23:42', '2025-07-03 18:26:09', 79429, '200.121.25.166', '200.121.25.166'),
(14, 6, '6qbg9pv8j59pmd6tsgkiddmprf', '2025-07-03 18:24:41', '2025-07-03 18:26:09', 79429, '200.121.25.166', '200.121.25.166'),
(15, 3, 'mkbsjagb44uskk20ks2014k368', '2025-07-03 20:42:09', NULL, NULL, '181.176.210.66', NULL),
(16, 5, '1epnp3rbvv573nu5q47osu38j9', '2025-07-03 20:44:06', NULL, NULL, '2803:a3e0:1737:7820:d1e0:2862:d5b4:3091', NULL),
(17, 5, 'bt9i7mspoao2so2ql1iucvnt8t', '2025-07-03 21:34:04', '2025-07-03 21:35:09', 65, '181.176.210.66', '181.176.210.66'),
(18, 3, 'lkc88q9s7dvr66r8ltf2lq725i', '2025-07-03 21:41:49', '2025-07-03 21:47:30', 341, '181.176.210.66', '181.176.210.66'),
(19, 4, 'o4uor50ca082ad119ftr7se9up', '2025-07-03 21:58:42', NULL, NULL, '2800:200:e240:16a8:85b6:a22d:2eeb:977', NULL),
(20, 3, '9t4pjjcirhkv4ru844ld3pkf28', '2025-07-03 22:10:27', '2025-07-03 22:24:24', 837, '181.176.210.66', '181.176.210.66'),
(21, 3, 'i7gqjrh3q3t2o6f748meandm40', '2025-07-03 22:19:52', '2025-07-04 17:40:49', 69657, '200.121.25.166', '38.25.18.25'),
(22, 3, 'uctqv8g2c29gkekgihr2cakeo9', '2025-07-03 22:27:09', '2025-07-03 22:38:41', 692, '181.176.210.66', '181.176.210.66'),
(23, 3, 'ddtdf03ptm2h3tqkg4u4njfu4f', '2025-07-03 22:41:13', '2025-07-03 22:42:53', 100, '181.176.210.66', '181.176.210.66'),
(24, 3, 'c0f3fg6qp4kkg418u21jfjjq0b', '2025-07-03 22:47:16', '2025-07-03 22:54:28', 432, '181.176.210.66', '181.176.210.66'),
(25, 3, '0ub5rtohp95fa2idanvm3ihfn9', '2025-07-04 01:51:14', '2025-07-04 10:41:12', 31798, '181.64.193.235', '181.64.193.235'),
(26, 5, 'h166uii7qrkh0cn7baasvqem51', '2025-07-04 10:41:31', '2025-07-04 11:17:31', 2160, '181.64.193.235', '181.64.193.235'),
(27, 7, 'ougt7ck5fd07bh39ijlo32eelk', '2025-07-04 13:50:20', NULL, NULL, '2800:200:e840:2432:b047:a9b2:8d42:d112', NULL),
(28, 3, 'e3ioet6l8c40jf1ubp1k7bkmbu', '2025-07-04 17:41:10', '2025-07-04 22:30:37', 17367, '38.25.18.25', '38.25.18.25'),
(29, 5, '1epnp3rbvv573nu5q47osu38j9', '2025-07-04 17:46:11', NULL, NULL, '2803:a3e0:1731:c060:90df:9fa:d0ee:c918', NULL),
(30, 4, 'o4uor50ca082ad119ftr7se9up', '2025-07-04 20:15:39', '2025-07-04 20:16:38', 59, '2800:200:e240:16a8:65b6:6d9d:6d84:e982', '2800:200:e240:16a8:65b6:6d9d:6d84:e982'),
(31, 4, 'ubp0g3osjmrtm0m31jevi9hqdi', '2025-07-04 20:21:50', NULL, NULL, '2800:200:e240:16a8:65b6:6d9d:6d84:e982', NULL),
(32, 6, 'dleqfnck0v22dhhb87s11eliqr', '2025-07-04 20:54:30', NULL, NULL, '38.25.53.141', NULL),
(33, 7, 'ougt7ck5fd07bh39ijlo32eelk', '2025-07-04 21:59:28', '2025-07-04 22:34:41', 2113, '2800:200:e840:2432:98f6:4b41:6cf8:212', '2800:200:e840:2432:5109:7671:ad6b:9796'),
(34, 3, 'lve489jo107ndqepn020cqmlbu', '2025-07-04 22:30:56', '2025-07-07 14:54:53', 231837, '38.25.18.25', '38.25.18.25'),
(35, 7, 'l0vfglufs63humi0qiohe85djm', '2025-07-04 22:35:42', NULL, NULL, '2800:200:e840:2432:5109:7671:ad6b:9796', NULL),
(36, 5, 'atgbp1a6v2nuceclh5thj5r7ep', '2025-07-05 00:14:37', NULL, NULL, '2803:a3e0:1731:c060:90df:9fa:d0ee:c918', NULL),
(37, 3, 'rh5jah2pla88as1gmu2eravin7', '2025-07-07 13:27:08', NULL, NULL, '181.64.193.235', NULL),
(38, 6, 'j4po9u6r5nl9gn488vtd56vfvo', '2025-07-07 14:43:13', NULL, NULL, '38.25.53.141', NULL),
(39, 3, '63bg2dbb155cvj9c6ps3npj9li', '2025-07-07 14:55:12', NULL, NULL, '38.25.18.25', NULL),
(40, 5, '13gpln70dpinetau8d23jr31et', '2025-07-08 11:04:52', NULL, NULL, '181.64.193.235', NULL),
(41, 3, '63bg2dbb155cvj9c6ps3npj9li', '2025-07-08 14:44:22', '2025-07-08 15:22:51', 2309, '200.121.25.166', '200.121.25.166'),
(42, 4, 'ubp0g3osjmrtm0m31jevi9hqdi', '2025-07-08 15:05:25', '2025-07-08 15:15:57', 632, '2800:200:e240:16a8:d870:e88d:c8e9:b738', '2800:200:e240:16a8:d870:e88d:c8e9:b738'),
(43, 4, '16uho45brk7ro43hgant0fufqf', '2025-07-08 15:16:22', '2025-07-08 15:18:29', 127, '2800:200:e240:16a8:d870:e88d:c8e9:b738', '2800:200:e240:16a8:d870:e88d:c8e9:b738'),
(44, 3, 'k972fl9vb5e9plh99rplbf566a', '2025-07-08 15:23:28', '2025-07-09 18:23:02', 97174, '200.121.25.166', '2001:1388:18:317d:2c4f:8041:e385:3cf'),
(45, 6, 'j4po9u6r5nl9gn488vtd56vfvo', '2025-07-08 15:23:36', NULL, NULL, '38.25.53.141', NULL),
(46, 4, '28tnoqulefl955a77i5n0go33g', '2025-07-08 15:24:56', NULL, NULL, '2800:200:e240:16a8:d870:e88d:c8e9:b738', NULL),
(47, 5, 'atgbp1a6v2nuceclh5thj5r7ep', '2025-07-08 15:28:56', '2025-07-08 20:44:03', 18907, '2803:a3e0:1731:47a0:68dd:2135:c5fd:ac97', '2803:a3e0:1731:47a0:68dd:2135:c5fd:ac97'),
(48, 5, 'mg5se86bp6kj5vihhm58rf7p0f', '2025-07-08 16:02:43', '2025-07-08 16:03:44', 61, '181.176.210.66', '181.176.210.66'),
(49, 5, 'ai2b0p3h90bd15l33q33kqvp2h', '2025-07-08 16:04:06', '2025-07-08 16:05:28', 82, '181.176.210.66', '181.176.210.66'),
(50, 5, '4ul8v07ps0trcc6u1og5q901n2', '2025-07-08 16:05:46', '2025-07-08 16:05:51', 5, '181.176.210.66', '181.176.210.66'),
(51, 3, 'uaqgtssddlsgc0k5gq6v7dukne', '2025-07-08 16:06:17', NULL, NULL, '181.176.210.66', NULL),
(52, 2, '5v9gdevsf13kc579b6op50ssoi', '2025-07-08 17:04:23', NULL, NULL, '45.231.74.210', NULL),
(53, 7, 'l0vfglufs63humi0qiohe85djm', '2025-07-08 17:07:22', '2025-07-08 18:18:54', 4292, '2800:200:e840:2432:4914:d5ab:4151:7b6b', '2800:200:e840:2432:4914:d5ab:4151:7b6b'),
(54, 7, 'gomanh82bhpm29lq3cgdkolkhd', '2025-07-08 18:19:10', '2025-07-08 21:45:00', 12350, '2800:200:e840:2432:4914:d5ab:4151:7b6b', '2800:200:e840:2432:8999:29fd:c423:2dd1'),
(55, 3, '84v9r7n6vntu4smk5d9i5rbsaq', '2025-07-08 20:16:13', NULL, NULL, '181.176.210.66', NULL),
(56, 5, '3radheq4a6bf08adnm6nkbujq9', '2025-07-08 20:44:18', '2025-07-08 20:44:30', 12, '2803:a3e0:1731:47a0:68dd:2135:c5fd:ac97', '2803:a3e0:1731:47a0:68dd:2135:c5fd:ac97'),
(57, 5, 'q4tcc45dmh1ob5ilovgk4uv3ln', '2025-07-08 20:44:47', NULL, NULL, '2803:a3e0:1731:47a0:68dd:2135:c5fd:ac97', NULL),
(58, 7, 'jnej5bh36ue6skt1jt0qjfeo9q', '2025-07-08 21:45:13', '2025-07-08 21:55:46', 633, '2800:200:e840:2432:8999:29fd:c423:2dd1', '2800:200:e840:2432:8999:29fd:c423:2dd1'),
(59, 7, '7dhv9m055lu5d5srpakkhkgo9c', '2025-07-08 21:56:56', NULL, NULL, '2800:200:e840:2432:8999:29fd:c423:2dd1', NULL),
(60, 7, '5hi0dk3869e4eld2p9a4rp4h4d', '2025-07-09 13:49:18', '2025-07-09 14:08:18', 1140, '2001:1388:18:317d:9c11:b788:3fad:7092', '2001:1388:18:317d:9c11:b788:3fad:7092'),
(61, 7, '4l7drr92elk9bc39flr1orhobc', '2025-07-09 14:09:07', NULL, NULL, '2001:1388:18:317d:9c11:b788:3fad:7092', NULL),
(62, 6, 'fd60b5vs000nqk0olk5r17hdd8', '2025-07-09 14:23:14', NULL, NULL, '2001:1388:18:317d:d3d:b024:faa8:fc43', NULL),
(63, 3, '4mgcfa7cejj7htlvlvbg2oseu5', '2025-07-09 18:23:15', NULL, NULL, '2001:1388:18:317d:2c4f:8041:e385:3cf', NULL),
(64, 5, 'ev7q9n9l26eko3asij3aqker26', '2025-07-09 21:40:22', NULL, NULL, '2803:a3e0:1731:47a0:20f6:e6b0:3ef3:51d9', NULL),
(65, 6, 'l4p63e5kq0jps599vamsetc61k', '2025-07-10 20:40:15', NULL, NULL, '38.25.53.141', NULL),
(66, 6, 'p3bp5q6ohkvid2jvjbsak6o1kj', '2025-07-10 21:34:39', NULL, NULL, '38.25.53.141', NULL),
(67, 6, 'nhfq4ueujjgmfdr8m4cpbt3ppc', '2025-07-11 14:25:16', NULL, NULL, '38.25.53.141', NULL),
(68, 3, 'p6n5oophhfuc7unk33eajipesa', '2025-07-14 09:54:01', NULL, NULL, '181.64.193.235', NULL),
(69, 6, '759che4leilq3c3lt8v524h617', '2025-07-14 14:11:26', NULL, NULL, '2001:1388:6563:471b:a089:f510:f9d5:cd7f', NULL),
(70, 5, 'eo10185jre1tdov41k9u5g2im9', '2025-07-16 14:00:35', '2025-07-17 02:16:43', 44168, '2001:1388:18:317d:8947:e6f4:c985:a48b', '2803:a3e0:1732:2830:357c:562b:54f9:22e7'),
(71, 7, 'u9jd80urpihi501hjjlv7m22j8', '2025-07-17 13:41:34', NULL, NULL, '2800:200:e840:2432:7533:6395:b08d:5ae7', NULL),
(72, 5, 'a9k6s4flbkhk8ca4n1vq6p5h9f', '2025-07-17 14:31:42', NULL, NULL, '2803:a3e0:1732:2830:357c:562b:54f9:22e7', NULL),
(73, 6, 'solt6g6ndf1pmtf0pd60v9hsge', '2025-07-17 15:38:11', NULL, NULL, '2001:1388:6563:6673:51ba:4b6:187:7bf5', NULL),
(74, 3, 'jcftoujuhhek6h0h0pldrdmusk', '2025-07-18 05:31:37', '2025-07-18 12:29:56', 25099, '181.64.193.222', '181.64.193.222'),
(75, 3, 'oej44u975shb7nvilcu2eoi1lj', '2025-07-18 12:46:59', NULL, NULL, '181.176.83.90', NULL),
(76, 6, '1e3f0rs8b9q1ugmos2us70o580', '2025-07-18 18:32:53', NULL, NULL, '38.25.53.141', NULL),
(77, 6, 'ln5o0cvjn5vlnmudbq2d81rdm8', '2025-07-18 18:54:14', NULL, NULL, '38.25.53.141', NULL),
(78, 3, 'rhc04e2m51p92r312hpvp99gfm', '2025-07-18 20:27:50', NULL, NULL, '181.176.83.90', NULL),
(79, 3, 'rhc04e2m51p92r312hpvp99gfm', '2025-07-18 20:27:51', NULL, NULL, '181.176.83.90', NULL),
(80, 3, '7env88gartohk6qt8u9m8jenhe', '2025-07-19 15:00:12', '2025-07-22 23:38:06', 290274, '181.64.193.222', '181.64.193.222'),
(81, 3, '7kmbr5bt8hphcep7n982m200fc', '2025-07-19 23:01:10', NULL, NULL, '181.64.193.222', NULL),
(82, 3, '7kmbr5bt8hphcep7n982m200fc', '2025-07-19 23:01:11', NULL, NULL, '181.64.193.222', NULL),
(83, 6, '6imbi6mjok1j453uc9fblrs17p', '2025-07-21 13:30:26', NULL, NULL, '38.25.53.141', NULL),
(84, 5, 'tjvdfpq6fg7b277usllqfi918n', '2025-07-21 14:24:57', NULL, NULL, '2803:a3e0:1732:2830:8a:b90e:5099:cd14', NULL),
(85, 4, 'usm629naibbk1n2j6sdrloqp9b', '2025-07-21 18:06:38', NULL, NULL, '2800:200:e240:16a8:dd22:1c2f:14e6:2a8f', NULL),
(86, 4, 'j3h6716t290jbcp1mssbjn7k3t', '2025-07-21 18:06:38', NULL, NULL, '2800:200:e240:16a8:dd22:1c2f:14e6:2a8f', NULL),
(87, 4, 'rjo075ql6gve0ebom5pld3fsd3', '2025-07-21 18:06:39', NULL, NULL, '2800:200:e240:16a8:dd22:1c2f:14e6:2a8f', NULL),
(88, 4, 'bm0o9as2qnajq2505guljl852c', '2025-07-21 18:07:54', NULL, NULL, '2800:200:e240:16a8:dd22:1c2f:14e6:2a8f', NULL),
(89, 6, '18maalgp2rar71v7j6ttpds6q1', '2025-07-21 21:09:02', NULL, NULL, '38.25.53.141', NULL),
(90, 3, '4mgcfa7cejj7htlvlvbg2oseu5', '2025-07-22 13:44:30', NULL, NULL, '2001:1388:18:317d:841f:bf9c:b558:1bde', NULL),
(91, 6, 'k0un6kfu4i51rmgp1lhpnrpelh', '2025-07-22 15:07:12', NULL, NULL, '2001:1388:18:317d:6437:5e7:eec4:7911', NULL),
(92, 3, 'eikaoqpse3e6upr1b7gpkr6vcb', '2025-07-22 23:38:39', '2025-07-23 00:04:57', 1578, '181.64.193.222', '181.64.193.222'),
(93, 8, 'u12vheav840qarjaf848ovadc8', '2025-07-23 00:05:25', NULL, NULL, '181.64.193.222', NULL),
(94, 5, 'cin5k8bl43lcpara4dj3n8252v', '2025-07-23 00:15:08', '2025-07-23 05:58:45', 20617, '181.64.193.222', '181.64.193.222'),
(95, 2, '8onav6h2i5a16e1ni2q0t5kd39', '2025-07-24 14:29:01', '2025-07-24 14:40:20', 679, '190.232.101.219', '190.232.101.219'),
(96, 6, 'rs6agruio2l9jrlr7mq9acr1of', '2025-07-25 21:40:19', NULL, NULL, '38.25.53.141', NULL),
(97, 6, 'g4vaf7d9ofn8s07nr6ujslf8f1', '2025-07-25 23:36:14', NULL, NULL, '38.25.53.141', NULL),
(98, 7, 'b43hnmvq0tssgmhpn1rj4f7f37', '2025-07-30 12:48:58', NULL, NULL, '179.6.14.108', NULL),
(99, 4, 'g7lq3grlk36skuke36oui158go', '2025-07-30 13:40:15', NULL, NULL, '2800:200:e240:16a8:94d8:ff34:ec88:e5ab', NULL),
(100, 5, '01i8dgmsrliurmnbllhio6nvgu', '2025-07-30 15:16:57', '2025-07-31 05:36:32', 51575, '2803:a3e0:1733:1ec0:4477:93e0:17f1:2128', '2803:a3e0:1733:1ec0:54dd:6641:d5e0:8528'),
(101, 6, '3r1mtpa6vsi4fishgdjbgo7tas', '2025-07-30 21:57:06', NULL, NULL, '38.25.53.141', NULL),
(102, 5, 'rvtf1unknmi82fltq17qhgoseb', '2025-07-31 14:58:25', '2025-07-31 23:07:43', 29358, '2803:a3e0:1731:7070:4cf1:4652:a855:c27f', '2803:a3e0:1731:7070:4cf1:4652:a855:c27f'),
(103, 6, '0v8e9cirhq9pjn7hm3e2rmam3p', '2025-07-31 15:08:29', NULL, NULL, '38.25.53.141', NULL),
(104, 4, 'g7lq3grlk36skuke36oui158go', '2025-07-31 15:15:19', NULL, NULL, '2800:200:e240:16a8:75ff:fe13:a0c5:402', NULL),
(105, 3, 'u12vheav840qarjaf848ovadc8', '2025-07-31 20:18:23', NULL, NULL, '181.64.193.222', NULL),
(106, 3, '4mgcfa7cejj7htlvlvbg2oseu5', '2025-07-31 20:53:42', NULL, NULL, '38.25.18.25', NULL),
(107, 6, 'lmndc80gfonhai8epj2s6id757', '2025-07-31 21:16:19', NULL, NULL, '38.25.53.141', NULL),
(108, 7, 'b43hnmvq0tssgmhpn1rj4f7f37', '2025-07-31 21:28:17', NULL, NULL, '2800:200:e840:2432:99a5:7600:fe01:964b', NULL),
(109, 3, 'sl1gpkmbkqk00q663l4t8l0sin', '2025-07-31 21:35:54', NULL, NULL, '2800:4b0:4501:25a0:1:0:6e5e:901f', NULL),
(110, 3, 'sl1gpkmbkqk00q663l4t8l0sin', '2025-07-31 21:35:55', NULL, NULL, '2800:4b0:4501:25a0:1:0:6e5e:901f', NULL),
(111, 5, 'j363tmpgb50m696cibearn4bbj', '2025-08-01 14:50:04', '2025-08-01 23:24:32', 30868, '2803:a3e0:1730:35c0:9f:80d6:c641:2b83', '2803:a3e0:1730:35c0:9f:80d6:c641:2b83'),
(112, 6, '27hee93m7j7u0ikbvtl6qekr4n', '2025-08-01 18:29:52', NULL, NULL, '38.25.53.141', NULL),
(113, 5, 'l185gdminbu2cc4o8t4ncduflq', '2025-08-01 23:25:39', '2025-08-01 23:26:33', 54, '2803:a3e0:1730:35c0:9f:80d6:c641:2b83', '2803:a3e0:1730:35c0:9f:80d6:c641:2b83'),
(114, 4, 'g7lq3grlk36skuke36oui158go', '2025-08-04 13:39:54', NULL, NULL, '2800:200:e240:16a8:9c59:4778:8fb:9567', NULL),
(115, 5, 'njrsuttr347vr4io4ndd4511vc', '2025-08-04 14:01:52', NULL, NULL, '2803:a3e0:1730:35c0:71dc:6eb5:bfb6:83e0', NULL),
(116, 3, 'ao5absl6asocoti89lkgkqt862', '2025-08-04 14:53:57', NULL, NULL, '38.25.18.25', NULL),
(117, 3, 'ao5absl6asocoti89lkgkqt862', '2025-08-04 14:53:58', NULL, NULL, '38.25.18.25', NULL),
(118, 3, 'ao5absl6asocoti89lkgkqt862', '2025-08-04 14:53:59', NULL, NULL, '38.25.18.25', NULL),
(119, 3, 'nsmaalb2br2isu4p0608o75unk', '2025-08-04 16:17:44', NULL, NULL, '34.176.44.62', NULL),
(120, 5, 'n5lst2nsnbhuiej8spgacp15t5', '2025-08-05 15:06:46', NULL, NULL, '2803:a3e0:1730:35c0:71dc:6eb5:bfb6:83e0', NULL),
(121, 4, 'phtas3q6p5juk06i57t59ed5k9', '2025-08-05 15:12:06', NULL, NULL, '2800:200:e240:16a8:69fa:8f56:cd8a:4f61', NULL),
(122, 3, '4mgcfa7cejj7htlvlvbg2oseu5', '2025-08-07 15:04:18', '2025-08-13 12:34:00', 509382, '2001:1388:18:f5a:3521:72bd:f075:346a', '2800:4b0:4202:d226:acac:2d80:c328:5d4b'),
(123, 3, 'huurdq9e0pl6a09rop1jkb9oph', '2025-08-08 07:39:15', NULL, NULL, '181.64.193.222', NULL),
(124, 4, 'eaesjcct11hckk6cheq4ff0bon', '2025-08-08 15:06:19', NULL, NULL, '2800:200:e240:16a8:e9e1:2b81:45d0:e97c', NULL),
(125, 5, '22k7hhjsir8ovvme366vq13tee', '2025-08-08 15:53:28', '2025-08-08 22:43:05', 24577, '2803:a3e0:1730:7df0:1d3:bae2:d136:ada9', '2803:a3e0:1730:7df0:1d3:bae2:d136:ada9'),
(126, 6, 'docqr33he2duu43047cdakcc75', '2025-08-08 20:12:39', NULL, NULL, '38.25.53.141', NULL),
(127, 5, 'serp764m5j5d59r1n6va93aqjs', '2025-08-08 22:43:21', '2025-08-08 22:45:40', 139, '2803:a3e0:1730:7df0:1d3:bae2:d136:ada9', '2803:a3e0:1730:7df0:1d3:bae2:d136:ada9'),
(128, 5, 'cp4rmm31o5kej9ueedp08s6j6v', '2025-08-11 14:20:43', NULL, NULL, '2803:a3e0:1730:7df0:b767:41b8:4ead:538b', NULL),
(129, 6, 'ji4c9p125do5856nlruo26g3a4', '2025-08-11 21:31:29', NULL, NULL, '38.25.53.141', NULL),
(130, 3, 'l7q87o8e55gjn1ut475iltponl', '2025-08-12 14:49:29', NULL, NULL, '190.235.170.136', NULL),
(131, 5, 'd0mvuiq0h8t8j8a0ir37fs11k4', '2025-08-12 15:32:07', NULL, NULL, '2803:a3e0:1732:b50:24:2ce2:1164:e7d1', NULL),
(132, 6, 'ivbpbbno39c60p7mrhca5i1ek7', '2025-08-12 21:11:13', NULL, NULL, '38.25.53.141', NULL),
(133, 3, '2k845rsbbvnu5ir7s70pn2jmu4', '2025-08-13 11:39:05', NULL, NULL, '190.235.170.136', NULL),
(134, 3, '7ruug20v0f9ngl7enq1gc2387r', '2025-08-13 12:34:45', '2025-08-15 18:08:40', 192835, '2800:4b0:4202:d226:acac:2d80:c328:5d4b', '38.25.25.89'),
(135, 6, 'k1tcs0r6mll701mvpnrg3t9ad1', '2025-08-13 17:00:49', NULL, NULL, '38.43.130.74', NULL),
(136, 3, '5lj0989r3k8n3cfqhhob3j1knc', '2025-08-13 22:33:04', NULL, NULL, '181.176.210.66', NULL),
(137, 3, 'g1mrs0t8nmash5f57ifhinh8j5', '2025-08-15 18:09:03', '2025-08-22 14:00:29', 589886, '38.25.25.89', '200.121.25.187'),
(138, 6, '0t3c77d5eo01gss3akk7oscvvo', '2025-08-15 22:37:11', NULL, NULL, '38.25.53.141', NULL),
(139, 5, '206q4gk1h3q3rm90vgas78np3e', '2025-08-16 01:07:26', '2025-08-16 01:34:42', 1636, '2803:a3e0:1732:b50:11d5:1b55:c9f9:24e0', '2803:a3e0:1732:b50:11d5:1b55:c9f9:24e0'),
(140, 3, 'vnfqnf97hku14q7j7noqljf35p', '2025-08-16 06:30:43', '2025-08-16 10:31:32', 14449, '190.235.170.35', '190.235.170.35'),
(141, 3, 'ilisl8c1vn5iot47ab3jite6pb', '2025-08-16 10:44:15', NULL, NULL, '190.235.170.35', NULL),
(142, 4, 'du2lp3j4dc5eba9l2jcus9k5sf', '2025-08-18 13:46:09', '2025-08-29 21:28:27', 978138, '2800:200:e240:12ad:559e:5f50:100a:ef61', '2800:200:e240:12ad:60dd:6379:6e90:17db'),
(143, 5, '0kjb7on6snspmu88u7d68evfkf', '2025-08-18 21:53:56', NULL, NULL, '2803:a3e0:1731:0:3c10:dbee:d022:29e3', NULL),
(144, 5, 'n20klhgml2fkm3int76ss6rlm7', '2025-08-19 15:33:55', NULL, NULL, '2803:a3e0:1731:0:a1f8:d625:9ec3:4826', NULL),
(145, 6, 'ufqbrsr702fcl7qr7ids548525', '2025-08-19 20:10:20', NULL, NULL, '38.25.53.141', NULL),
(146, 5, '85ng042fbl536efoh17kuvc7iu', '2025-08-21 15:11:21', NULL, NULL, '2803:a3e0:1731:0:f0c0:66fb:743d:bd5f', NULL),
(147, 5, 'hr0fpnisr94ps0g96ps2uvmpc1', '2025-08-21 22:26:43', NULL, NULL, '2803:a3e0:1731:0:79f8:2c23:9672:7875', NULL),
(148, 5, 'hr0fpnisr94ps0g96ps2uvmpc1', '2025-08-21 23:52:50', NULL, NULL, '2803:a3e0:1731:0:79f8:2c23:9672:7875', NULL),
(149, 6, 'nldkrkrnnrf724rkrp4r0aochp', '2025-08-22 13:37:39', NULL, NULL, '38.25.53.141', NULL),
(150, 3, 'g5nvnad8hovogsurdtrtt6nhlc', '2025-08-22 14:01:09', NULL, NULL, '200.121.25.187', NULL),
(151, 3, 'cpo55nt7hdm5c0gtnriqosevk9', '2025-08-22 18:44:11', NULL, NULL, '2800:4b0:4033:4622:1:0:d3f4:adec', NULL),
(152, 3, 'cpo55nt7hdm5c0gtnriqosevk9', '2025-08-22 18:44:12', NULL, NULL, '2800:4b0:4033:4622:1:0:d3f4:adec', NULL),
(153, 3, 'rdg439k3degv50abj5n76vnu23', '2025-08-22 19:12:44', NULL, NULL, '2800:4b0:4033:4622:1:0:d3f4:adec', NULL),
(154, 3, 'lsrd8lo3g02snrgj8elhtlph27', '2025-08-22 22:48:18', '2025-08-22 22:51:26', 188, '181.176.210.66', '181.176.210.66'),
(155, 5, 'dh6h3h4cresfqjsq7ev8is598n', '2025-08-25 14:12:30', NULL, NULL, '2803:a3e0:1731:0:fb0e:6784:f535:199d', NULL),
(156, 6, '16hsbr81sfucvt1mj62tihr8jp', '2025-08-25 16:07:03', NULL, NULL, '38.25.53.141', NULL),
(157, 6, 'mk6ih0g2bu187gaotd7nup9g59', '2025-08-25 17:39:13', '2025-08-25 17:39:39', 26, '38.25.53.141', '38.25.53.141'),
(158, 6, 'cak6o6tr92sq05uc4m1at7s2n2', '2025-08-25 17:39:42', '2025-08-25 17:39:52', 10, '38.25.53.141', '38.25.53.141'),
(159, 6, '9ervi9crppfkt5ofha6kdnsptu', '2025-08-25 17:40:00', NULL, NULL, '38.25.53.141', NULL),
(160, 6, 'qtjld6do00ed1dj72rekg98ldo', '2025-08-25 18:29:06', NULL, NULL, '38.25.53.141', NULL),
(161, 5, 'rc1n40mapb7ft5s1qa6h7r63mc', '2025-08-25 23:43:14', NULL, NULL, '2803:a3e0:1731:0:10a0:a994:cb79:2c69', NULL),
(162, 5, '678h10gc6qbrh3goq6fkkhda74', '2025-08-26 17:21:44', '2025-08-29 01:40:17', 202713, '2803:a3e0:1731:0:a4f5:db02:485d:71dd', '2803:a3e0:1731:0:dce8:2bfa:1ab8:dbc4'),
(163, 6, 'ale2kdd7r0t3f9n4pemjbflj6j', '2025-08-29 14:40:51', NULL, NULL, '38.25.53.141', NULL),
(164, 5, 'ue9qlpjnanbr315cgicpi3f1fp', '2025-08-29 16:39:13', '2025-09-01 00:21:38', 200545, '2803:a3e0:1731:0:851b:48e1:bfe1:cf71', '2803:a3e0:1731:0:d495:cd90:4144:fb94'),
(165, 6, 'pqnskjmu6p5l3f5b06jiq0rv72', '2025-08-29 16:48:04', NULL, NULL, '38.25.53.141', NULL),
(166, 6, '8t40vsjlqfi3t56al7mdbr6jaq', '2025-08-29 21:17:08', NULL, NULL, '38.25.53.141', NULL),
(167, 4, 'cool664q6v0r91jp552q2ci5pa', '2025-08-29 21:28:37', NULL, NULL, '2800:200:e240:12ad:60dd:6379:6e90:17db', NULL),
(168, 3, 'jctn2rq6rlev53io92actgsdsp', '2025-09-01 14:40:09', NULL, NULL, '38.25.25.89', NULL),
(169, 3, 'jctn2rq6rlev53io92actgsdsp', '2025-09-01 14:40:10', NULL, NULL, '38.25.25.89', NULL),
(170, 5, '6js5cov09egf8n80hk4h4rib6n', '2025-09-01 15:11:04', NULL, NULL, '2803:a3e0:1731:0:d495:cd90:4144:fb94', NULL),
(171, 5, '0nlgqmsl55o7cuoonfm8o4kov8', '2025-09-03 13:43:28', NULL, NULL, '2001:1388:18:51f0:3028:d79d:7751:17b3', NULL),
(172, 3, 'md9hjjm4l6d3nas8r3s3uuam1l', '2025-09-03 13:55:42', NULL, NULL, '2001:1388:18:51f0:4431:e2d1:49b1:761d', NULL),
(173, 5, '64q6o02apgevful6pibhm7dqj6', '2025-09-03 17:43:16', NULL, NULL, '2001:1388:18:51f0:3028:d79d:7751:17b3', NULL),
(174, 6, 'ui6kb24qi1hi3b63saaf1arrhd', '2025-09-03 18:27:51', NULL, NULL, '2001:1388:18:51f0:951b:281d:39bf:6093', NULL),
(175, 2, 'gf62ga580rrcccoa1s7anqqgj2', '2025-09-03 19:53:32', NULL, NULL, '2001:1388:18:51f0:b9bb:d04e:910:b70b', NULL),
(176, 5, '8edmrm9tj89ldm0aip51tf77gf', '2025-09-04 16:27:52', NULL, NULL, '2803:a3e0:1730:de20:9c02:4c6c:2f8d:3df9', NULL),
(177, 5, '46v6mrq5p7ce09meugldvfiaqt', '2025-09-04 20:20:18', NULL, NULL, '2803:a3e0:1730:3ed0:109f:5002:5285:d26b', NULL),
(178, 4, 'qbus6dvmmh8dk8n46fo6mpllq7', '2025-09-05 15:47:15', NULL, NULL, '2800:200:e240:12ad:14a5:6cca:570e:260c', NULL),
(179, 6, 'h1jfk14ulh781pptia8pdqtdli', '2025-09-05 21:11:25', NULL, NULL, '38.25.53.141', NULL),
(180, 5, 'tilfbs1m08v9osji367hcjiree', '2025-09-07 21:57:31', '2025-09-08 01:18:30', 12059, '2803:a3e0:1730:3ed0:2806:8644:f0f:24a', '2803:a3e0:1730:3ed0:2806:8644:f0f:24a'),
(181, 5, 'licu58mnv1v0ek5931r828gv2k', '2025-09-08 01:18:34', NULL, NULL, '2803:a3e0:1730:3ed0:2806:8644:f0f:24a', NULL),
(182, 4, '1hq7m2n1oer4qo59360gr7ohet', '2025-09-08 13:48:43', NULL, NULL, '2800:200:e240:12ad:25f4:b9fa:10c9:b96a', NULL),
(183, 3, '4dkdbcb9iprtd8gd7om5p1jlrv', '2025-09-08 14:21:56', NULL, NULL, '38.25.25.89', NULL),
(184, 3, '4dkdbcb9iprtd8gd7om5p1jlrv', '2025-09-08 14:21:57', NULL, NULL, '38.25.25.89', NULL),
(185, 3, '4dkdbcb9iprtd8gd7om5p1jlrv', '2025-09-08 14:21:58', NULL, NULL, '38.25.25.89', NULL),
(186, 5, 'sl6j1mqnp973f0jjaeslguvjbf', '2025-09-08 22:56:00', NULL, NULL, '2803:a3e0:1730:3ed0:e476:c203:198:e364', NULL),
(187, 4, 'qfeb1hdbnnac545fr0nhnd3ssr', '2025-09-09 13:42:09', NULL, NULL, '2800:200:e240:12ad:7123:47dc:7432:9240', NULL),
(188, 5, '189qmuk442hm5d32s60aalccue', '2025-09-09 14:40:21', '2025-09-10 00:06:49', 33988, '2803:a3e0:1730:3ed0:e476:c203:198:e364', '2803:a3e0:1730:3ed0:5827:3f34:4ad0:4351'),
(189, 5, '7f7ujc8s5ivm79v9gv657lq2bs', '2025-09-10 14:34:51', NULL, NULL, '2803:a3e0:1730:3ed0:5827:3f34:4ad0:4351', NULL),
(190, 4, 'lve6hbt47n8885e2tvk6mae8qe', '2025-09-10 16:56:43', NULL, NULL, '2800:200:e240:12ad:5544:e683:beb9:d83c', NULL),
(191, 5, 'mvn50nh48l3bpjgqa85vg2jqu0', '2025-09-11 15:35:30', '2025-09-11 18:59:44', 12254, '2803:a3e0:1730:3ed0:bd44:f85d:454d:78ec', '2803:a3e0:1730:3ed0:bd44:f85d:454d:78ec'),
(192, 5, '0vms9e3eieits2ti5ntlcjuhg3', '2025-09-11 19:53:39', NULL, NULL, '2803:a3e0:1730:3ed0:808f:e29f:27b4:9236', NULL),
(193, 5, 'vlrnspqtrduj227ue0ebdgbr7k', '2025-09-11 20:06:12', NULL, NULL, '2803:a3e0:1730:3ed0:808f:e29f:27b4:9236', NULL),
(194, 4, 'kjeb0s2lqmoq0dd9d4t85543l6', '2025-09-11 20:59:52', NULL, NULL, '2800:200:e240:12ad:a491:4f63:9075:a659', NULL),
(195, 5, 'higr70h150g0630ekibmm9nafq', '2025-09-12 17:29:31', NULL, NULL, '132.157.129.200', NULL),
(196, 5, 'higr70h150g0630ekibmm9nafq', '2025-09-12 17:29:32', NULL, NULL, '132.157.129.200', NULL),
(197, 5, '0er7f12m1p7409gu25i27rul52', '2025-09-15 04:29:38', NULL, NULL, '2803:a3e0:1730:3ed0:21f6:79d1:abb0:7cbb', NULL),
(198, 4, 'u4455gjshe4e96ml3qfg1k6v78', '2025-09-15 13:36:17', NULL, NULL, '2800:200:e240:12ad:54ec:febc:504:4506', NULL),
(199, 4, '0a6f8o3vm7v9or5thablq8l1mm', '2025-09-16 14:33:50', NULL, NULL, '2800:200:e240:12ad:940b:4283:fb3f:cc56', NULL),
(200, 3, 'sfu48c99614g3g1f1c84e8of3v', '2025-09-17 14:57:38', NULL, NULL, '2001:1388:18:51f0:88fe:2df9:828:29e6', NULL),
(201, 5, 'md1e2jvjrrg1jop8l7fcsl0ckk', '2025-09-18 15:28:40', '2025-09-20 05:35:12', 137192, '2803:a3e0:1730:3ed0:b451:4ff4:a3ce:a2a5', '2803:a3e0:1734:7c70:7091:a69c:86a5:ca0e'),
(202, 3, '514pp170v36ah2brnhp8l3sav5', '2025-09-19 17:13:30', NULL, NULL, '38.25.25.89', NULL),
(203, 4, 'rbn48e97ihu5hf7a8hrhl6r4jo', '2025-09-19 21:36:05', NULL, NULL, '2800:200:e240:12ad:f033:63f2:4d9f:432e', NULL),
(204, 5, 'djm0t0rg09ehbimfs2ahmrgoh8', '2025-09-20 05:42:02', '2025-09-20 05:42:44', 42, '2803:a3e0:1734:7c70:7091:a69c:86a5:ca0e', '2803:a3e0:1734:7c70:7091:a69c:86a5:ca0e'),
(205, 4, 'p7tb4qrglii8m1ssvipr5l0nq2', '2025-09-22 13:31:30', NULL, NULL, '2800:200:e240:12ad:980a:4fc6:6751:a0d', NULL),
(206, 5, 'ak7opp1svs6669fj9gicoqkhfo', '2025-09-22 14:49:46', NULL, NULL, '2803:a3e0:1734:7c70:498e:77a9:f638:b682', NULL),
(207, 4, 'iqpu9bfc7b78lrosgu2uoinlbf', '2025-09-23 13:52:14', NULL, NULL, '2800:200:e240:12ad:59e7:e11a:9913:bc3c', NULL),
(208, 3, '9rs4ikdj86r70j9lrgtlvam8a2', '2025-09-23 17:14:52', NULL, NULL, '38.25.25.89', NULL),
(209, 5, 'ak7opp1svs6669fj9gicoqkhfo', '2025-09-23 18:33:09', NULL, NULL, '2803:a3e0:1730:36c0:34c4:6c07:d465:7eee', NULL),
(210, 5, '69s94l0j2su30n622sjlluc37r', '2025-09-24 13:41:11', NULL, NULL, '2001:1388:18:51f0:5c87:2408:d7b6:67a', NULL),
(211, 3, '514pp170v36ah2brnhp8l3sav5', '2025-09-24 13:57:54', NULL, NULL, '38.43.130.123', NULL),
(212, 4, '13279u9bodvm313qakesqpk8s9', '2025-09-24 15:33:32', NULL, NULL, '38.43.130.123', NULL),
(213, 5, 'u7t0tjnjsasda7ddl21dou26l4', '2025-09-26 14:42:40', NULL, NULL, '2803:a3e0:1730:bc0:e117:df5f:d6e2:15b9', NULL),
(214, 5, 'mj6c3593q2vaicb41011sgvm9s', '2025-09-26 23:10:52', NULL, NULL, '2803:a3e0:1730:bc0:c6:8de5:bb9:104b', NULL),
(215, 5, 'rbevskbo4srhlj647vgjr27301', '2025-09-26 23:14:16', NULL, NULL, '2803:a3e0:1730:bc0:c6:8de5:bb9:104b', NULL),
(216, 5, 'uvl22qqflqtdjoa7jjg7l2j8k9', '2025-09-26 23:21:12', NULL, NULL, '2803:a3e0:1730:bc0:c6:8de5:bb9:104b', NULL),
(217, 5, '4bptfirs7k3d2p7bjjq7u19kmm', '2025-09-27 06:33:28', NULL, NULL, '2803:a3e0:1730:bc0:c6:8de5:bb9:104b', NULL),
(218, 5, '4bptfirs7k3d2p7bjjq7u19kmm', '2025-09-27 06:33:29', NULL, NULL, '2803:a3e0:1730:bc0:c6:8de5:bb9:104b', NULL),
(219, 5, '4bptfirs7k3d2p7bjjq7u19kmm', '2025-09-27 06:33:30', NULL, NULL, '2803:a3e0:1730:bc0:c6:8de5:bb9:104b', NULL),
(220, 4, 'prri28f5oujqf289n4m52t90uc', '2025-09-29 13:34:03', '2025-09-29 14:44:54', 4251, '2800:200:e240:12ad:c42a:30f4:34eb:1fea', '2800:200:e240:12ad:c42a:30f4:34eb:1fea'),
(221, 4, 'gg70p5unh47o1t725o4e5lngef', '2025-09-29 14:45:10', NULL, NULL, '2800:200:e240:12ad:c42a:30f4:34eb:1fea', NULL),
(222, 5, 'mr1t6vrka7a4fpmdm5usdcdo1s', '2025-09-29 17:11:51', NULL, NULL, '2803:a3e0:1730:bc0:e057:f300:b38a:7505', NULL),
(223, 4, 'roueu8n03bhid547j6bhdpf2jp', '2025-09-30 19:21:49', NULL, NULL, '2800:200:e240:12ad:48df:10b2:7f39:4b3b', NULL),
(224, 4, 'roueu8n03bhid547j6bhdpf2jp', '2025-09-30 19:21:50', NULL, NULL, '2800:200:e240:12ad:48df:10b2:7f39:4b3b', NULL),
(225, 5, '7phmhpnag24qhh9spohlo1i2st', '2025-09-30 20:00:01', '2025-10-01 00:30:11', 16210, '2803:a3e0:1730:bc0:b8d0:8cd2:51eb:351f', '2803:a3e0:1730:bc0:b8d0:8cd2:51eb:351f'),
(226, 5, 'uu92tbo2e81lvq62tanq4k26ku', '2025-10-01 00:30:29', '2025-10-01 00:41:32', 663, '2803:a3e0:1730:bc0:b8d0:8cd2:51eb:351f', '2803:a3e0:1730:bc0:b8d0:8cd2:51eb:351f'),
(227, 4, '0jq05pv7qbp8ionm4tfcom06fs', '2025-10-01 00:35:18', NULL, NULL, '2800:200:e240:12ad:3eb1:1891:3af2:91c7', NULL),
(228, 4, '0jq05pv7qbp8ionm4tfcom06fs', '2025-10-01 00:35:18', NULL, NULL, '2800:200:e240:12ad:3eb1:1891:3af2:91c7', NULL),
(229, 3, 'vqf7tf587k19mkqu4708vq98qu', '2025-10-01 13:02:43', NULL, NULL, '2800:4b0:4413:2665:5945:48c6:9b54:d330', NULL),
(230, 5, 'uiif2gjrvg0hp8bmugmhd2eqm8', '2025-10-01 13:39:57', NULL, NULL, '2001:1388:18:19fe:6da8:5121:88f7:90fd', NULL),
(231, 4, '9nuf45lqaag1g37enlc9v42ibs', '2025-10-01 17:55:55', NULL, NULL, '2001:1388:18:19fe:90cc:6de3:5c0c:d627', NULL),
(232, 4, 'u2a95gnt66i9m1eepg7ia6174i', '2025-10-03 17:15:58', NULL, NULL, '2800:200:e240:12ad:9807:15e1:8421:5523', NULL),
(233, 3, 'ghha5h4o7upgs55ioqikpjlaee', '2025-10-03 20:12:08', NULL, NULL, '38.25.25.89', NULL),
(234, 4, 'ajo3044ubsoulp43j9r89b417d', '2025-10-06 14:02:58', NULL, NULL, '2800:200:e240:12ad:bb34:1279:81c3:c5f6', NULL),
(235, 5, '1f210ane91mtci1nujn60h68tr', '2025-10-06 14:37:03', NULL, NULL, '2803:a3e0:1731:c620:98dc:56ce:7905:c782', NULL),
(236, 9, 'tkncj3ar301v8p07vurclmal9v', '2025-10-06 17:59:38', NULL, NULL, '132.251.1.55', NULL),
(237, 4, 'qf9p2hcprctvbef4gd71f1ogmu', '2025-10-07 14:18:43', NULL, NULL, '2800:200:e240:12ad:a019:c1df:3eab:fc8e', NULL),
(238, 9, 'm0t90t616grtf33d2be2m23s2c', '2025-10-07 21:21:50', NULL, NULL, '132.251.1.95', NULL),
(239, 4, 'k6oh6cc5cb7uidqlvsar7afb9i', '2025-10-07 21:32:15', NULL, NULL, '2800:200:e240:12ad:b82b:695b:a14c:1aa3', NULL),
(240, 5, 'qjfgd8voa7mnrrt53rq6c2fcpe', '2025-10-07 22:36:52', NULL, NULL, '2803:a3e0:1731:c620:e13c:bf42:70fe:b605', NULL),
(241, 9, 'd2ah9d9mvq05vqed5fv3ml41d3', '2025-10-08 13:54:04', NULL, NULL, '132.251.1.95', NULL),
(242, 9, 'j8i0ulfhrpdvvlraejtru3u91f', '2025-10-09 14:32:17', NULL, NULL, '132.251.1.95', NULL),
(243, 4, 'muskur8t9ver1jr794mgekum7b', '2025-10-09 20:30:00', NULL, NULL, '45.182.39.18', NULL),
(244, 4, '9b5m0d3et81rdpnv2gv29n09lk', '2025-10-10 15:16:21', NULL, NULL, '2800:200:e240:12ad:68f9:336a:50cc:866d', NULL),
(245, 5, 'krhgpr2nj3ugm9pthg34otivgb', '2025-10-10 19:30:10', '2025-10-10 22:29:50', 10780, '2803:a3e0:1731:c620:35fa:5821:deaf:a66e', '2803:a3e0:1731:c620:35fa:5821:deaf:a66e'),
(246, 3, '884mulq4i8mtrlb4e90t50chct', '2025-10-10 20:54:44', '2025-10-13 14:54:27', 237583, '38.25.25.89', '2001:1388:18:2b4c:a456:dd80:15ec:8df8'),
(247, 5, 'nnuis7oil784qku39che9r2nha', '2025-10-13 14:40:56', NULL, NULL, '2803:a3e0:1731:c620:9a6c:720d:b4ce:afc3', NULL),
(248, 10, 'veciei2en8gq8ma7ck6351rdop', '2025-10-13 14:54:57', '2025-10-13 15:22:26', 1649, '2001:1388:18:2b4c:a456:dd80:15ec:8df8', '2001:1388:18:2b4c:a456:dd80:15ec:8df8'),
(249, 4, 'alhkqju96n8qm57tuftolokul2', '2025-10-13 15:09:43', NULL, NULL, '2800:200:e240:12ad:dcca:9488:972f:6a12', NULL),
(250, 3, 'gnggs7p6q7illlc3fd9cmdg6e3', '2025-10-13 15:22:30', NULL, NULL, '2001:1388:18:2b4c:a456:dd80:15ec:8df8', NULL),
(251, 9, 'ol4of1j6uufn1i40971dkisv43', '2025-10-13 15:44:36', NULL, NULL, '132.191.2.104', NULL),
(252, 10, 'j6saen2i3f6s1ef1t27elhlhf6', '2025-10-13 19:55:37', NULL, NULL, '2001:1388:62a:59a4:563d:e39:1563:f380', NULL),
(253, 4, 'inohrq3p3fvssh6g2gdlgk09b7', '2025-10-14 17:40:06', '2025-10-14 20:59:13', 11947, '2800:200:e240:12ad:21ef:b2:564d:c96', '2800:200:e240:12ad:35eb:12c:3cc7:feba'),
(254, 4, 'j8p8ete3sv605vsfuko13uhit7', '2025-10-14 20:59:43', NULL, NULL, '2800:200:e240:12ad:35eb:12c:3cc7:feba', NULL),
(255, 4, 'dn8st8ehvv005k4sh14jl27k6s', '2025-10-15 17:17:51', NULL, NULL, '2800:200:e240:12ad:b556:84c8:a3e:5f20', NULL),
(256, 3, '9v6f8vudv6nb4a9tco85ja16vq', '2025-10-16 16:08:20', NULL, NULL, '2001:1388:18:2b4c:50d0:6d3d:63e7:fd6e', NULL),
(257, 4, '7loe79ucg3jrum12eb6eibc07v', '2025-10-16 16:08:22', NULL, NULL, '2001:1388:18:2b4c:414d:d25f:ef34:36d', NULL),
(258, 3, '1s2tk6ka3r3ahir6hdvqebobak', '2025-10-16 20:07:32', NULL, NULL, '2800:4b0:440e:c215:186e:f362:1d98:e179', NULL),
(259, 3, '1s2tk6ka3r3ahir6hdvqebobak', '2025-10-16 20:07:33', NULL, NULL, '2800:4b0:440e:c215:186e:f362:1d98:e179', NULL),
(260, 4, 'fuh23umllbs7l4325rti5vnogu', '2025-10-17 13:53:34', NULL, NULL, '190.238.68.208', NULL),
(261, 5, 'nnuis7oil784qku39che9r2nha', '2025-10-17 14:19:32', NULL, NULL, '2803:a3e0:1731:b670:dd43:46ce:a65f:3e29', NULL),
(262, 4, 'v5cf7tm2jt87d59o5bjd71bt56', '2025-10-20 13:27:07', NULL, NULL, '38.250.159.21', NULL),
(263, 9, 'ol4of1j6uufn1i40971dkisv43', '2025-10-20 13:35:18', NULL, NULL, '132.251.2.74', NULL),
(264, 4, 'doplp6fd8tpt5uhsh4b8bjcbq4', '2025-10-21 15:46:05', NULL, NULL, '2800:200:e240:12ad:8d9c:b783:82d:c5b0', NULL),
(265, 5, 'brskvd9ipueri6mveavercp1db', '2025-10-22 13:41:23', NULL, NULL, '2001:1388:18:2b4c:d1c0:3e54:cd0b:c49', NULL),
(266, 4, '1r94nl1k91asihht1fdfqjpu0p', '2025-10-22 14:09:37', NULL, NULL, '2001:1388:18:2b4c:45b3:e578:f2df:bb62', NULL),
(267, 9, 'a4g3kkm5g31l9tft56qob1plsn', '2025-10-23 14:34:10', NULL, NULL, '132.191.2.110', NULL),
(268, 5, 'gdqbttb9mpmu9dmt75tejn4lsf', '2025-10-23 14:37:33', '2025-10-24 20:44:38', 108425, '2803:a3e0:1730:7f30:6d31:f8c9:740e:3756', '2803:a3e0:1730:7f30:7053:8274:2e0:7e47'),
(269, 4, 'sossl0el6k8f27v6nfi76ooupg', '2025-10-24 16:19:51', '2025-10-24 20:03:42', 13431, '2800:200:e240:12ad:a0fa:c57e:a0d7:ae17', '2800:200:e240:12ad:c174:1f0e:6724:b2fb'),
(270, 3, 'lpqsgduuhudmn5p1lu7na6mkm2', '2025-10-24 18:24:11', NULL, NULL, '38.25.25.89', NULL),
(271, 4, 'vtu3qnj27gs2rb4h7nup0neni5', '2025-10-24 20:03:45', NULL, NULL, '2800:200:e240:12ad:c174:1f0e:6724:b2fb', NULL),
(272, 9, 'ahbimfcjui3pcqc6bi8o3kk1s2', '2025-10-27 12:13:22', NULL, NULL, '132.191.2.110', NULL),
(273, 4, 'epa2luncstt1olr7vjgki4evvc', '2025-10-27 13:20:34', NULL, NULL, '2800:200:e240:12ad:40f6:32e:3521:75e0', NULL),
(274, 5, 'jpj34h35bf4ni5m4r76ndb992s', '2025-10-27 13:30:48', '2025-10-31 23:45:45', 382497, '2803:a3e0:1730:7f30:9d34:2a9a:1254:691e', '2803:a3e0:1730:7f30:d0a7:df2f:c08:f85c'),
(275, 3, '8eh4nau5jht6pc1j3vdr6qjeff', '2025-10-27 14:31:45', NULL, NULL, '38.25.25.89', NULL),
(276, 3, 'r27qp9n04olbhioc5fai7thgbr', '2025-10-30 16:26:19', NULL, NULL, '38.25.25.89', NULL),
(277, 9, '7svqkse4grnv2drp1u8heve73p', '2025-10-30 16:27:57', NULL, NULL, '132.191.2.127', NULL),
(278, 4, '4k9egfa7bmick4i0quhl0v6g9p', '2025-10-30 18:17:16', '2025-10-31 16:47:19', 81003, '2800:200:e240:12ad:c56b:aa9e:bd79:c914', '2800:200:e240:12ad:f896:e378:1bd4:5f05'),
(279, 4, '2q3uic2ie2em2o5ojbujeh9sev', '2025-10-31 16:47:22', NULL, NULL, '2800:200:e240:12ad:f896:e378:1bd4:5f05', NULL),
(280, 3, 'r27qp9n04olbhioc5fai7thgbr', '2025-10-31 20:50:21', NULL, NULL, '38.25.25.89', NULL),
(281, 9, '7svqkse4grnv2drp1u8heve73p', '2025-10-31 21:35:10', '2025-10-31 23:01:09', 5159, '132.191.2.127', '132.191.2.127'),
(282, 9, 's59qbh24umueec8rtgtutimmpk', '2025-10-31 23:01:13', NULL, NULL, '132.191.2.127', NULL),
(283, 3, 'g5pncqa4tkvi24jqlija4phvn4', '2025-10-31 23:24:30', NULL, NULL, '2800:4b0:5312:16f3:1873:110a:640c:96dc', NULL),
(284, 3, 'g5pncqa4tkvi24jqlija4phvn4', '2025-10-31 23:24:31', NULL, NULL, '2800:4b0:5312:16f3:1873:110a:640c:96dc', NULL),
(285, 3, '4v6l173rjm96affp3jpqg0qsr9', '2025-10-31 23:55:44', NULL, NULL, '2800:4b0:5312:16f3:1873:110a:640c:96dc', NULL),
(286, 3, '4v6l173rjm96affp3jpqg0qsr9', '2025-10-31 23:55:45', NULL, NULL, '2800:4b0:5312:16f3:1873:110a:640c:96dc', NULL),
(287, 4, 'n3mnmqjl1njj0bcpmo1g31l3ph', '2025-11-03 13:38:36', NULL, NULL, '2800:200:e240:12ad:6de0:50f4:54b3:70a2', NULL),
(288, 9, 'rmg21fcntc822oq9r6h6vior3a', '2025-11-03 13:38:37', NULL, NULL, '132.191.2.127', NULL),
(289, 3, '05o1br64lpmil3o7jmalutt1cc', '2025-11-03 13:39:23', NULL, NULL, '38.25.25.89', NULL),
(290, 5, 'n0l8tps8q2aqdhgss86at48qtc', '2025-11-03 13:47:31', NULL, NULL, '2803:a3e0:1730:7f30:9d34:2a9a:1254:691e', NULL),
(291, 5, 'ggsm7iu46gt9f431qrvq2hac6d', '2025-11-03 18:09:22', NULL, NULL, '2803:a3e0:1730:7f30:9d34:2a9a:1254:691e', NULL),
(292, 5, 'uucncls4rkm5jun6stfdeuvfa9', '2025-11-03 21:37:52', NULL, NULL, '2803:a3e0:1730:7f30:9d34:2a9a:1254:691e', NULL),
(293, 4, 'ds717bchk1cigaduulbq11q0b3', '2025-11-05 13:49:06', NULL, NULL, '2800:200:e240:12ad:dd3e:e281:d5f:3f09', NULL),
(294, 9, 'mq8bsip6h0ggpqfbl9aevjvr7l', '2025-11-05 21:47:33', NULL, NULL, '132.251.0.33', NULL),
(295, 3, 'p285mir02pqtch628rru7102oo', '2025-11-05 22:38:28', '2025-11-05 23:49:48', 4280, '181.176.210.66', '181.176.210.66'),
(296, 3, 'h73t0lgkojdr86sjur3tq6evam', '2025-11-06 15:39:54', NULL, NULL, '181.176.210.66', NULL),
(297, 4, '665ihllk810937rbm98frk32pn', '2025-11-06 16:04:48', NULL, NULL, '2800:200:e240:12ad:86d:dcba:b5a3:bfdd', NULL),
(298, 5, 'kupvm3cga2c09bc2h6qpb0antj', '2025-11-06 16:53:31', '2025-11-07 01:48:27', 32096, '2803:a3e0:1732:7c0:1030:e4ca:5ebe:9c6d', '132.251.0.201'),
(299, 3, '9316c4fkke84e75l1f005ldkua', '2025-11-07 14:05:12', NULL, NULL, '181.176.210.66', NULL),
(300, 4, '07oo6q4efkchvr7ismder5el8s', '2025-11-07 16:47:42', NULL, NULL, '2800:200:e240:12ad:902c:376:e6f1:2b81', NULL),
(301, 5, 'gkq20v8vf105poqbocelaad70k', '2025-11-07 18:56:22', '2025-11-08 00:23:51', 19649, '2803:a3e0:1731:b300:80e0:8bf8:27e4:9c77', '2803:a3e0:1731:b300:80e0:8bf8:27e4:9c77'),
(302, 3, 'aob281r8d8cb1mgon8mr585eq3', '2025-11-07 20:07:01', NULL, NULL, '181.176.210.66', NULL),
(303, 4, 'ulk27mvm4p3383cor6jjmk02h2', '2025-11-07 23:38:38', NULL, NULL, '2800:200:e240:12ad:704e:82f2:271d:af40', NULL),
(304, 3, 'e91sude7iv6s9fut34hsdok5r6', '2025-11-08 02:33:47', '2025-11-08 03:14:03', 2416, '181.176.210.66', '181.176.210.66'),
(305, 4, '12ccgsh2cmqqil3uqf3khke25q', '2025-11-10 13:36:56', NULL, NULL, '2800:200:e240:12ad:c846:aa29:5de7:a92a', NULL),
(306, 5, 'nsp9mljo9tf5qf0kljcicbhd1o', '2025-11-10 13:42:00', '2025-11-12 00:44:31', 126151, '2803:a3e0:1731:b300:fe8b:c0a5:ba50:4474', '2803:a3e0:1731:b300:fe8b:c0a5:ba50:4474'),
(307, 3, 'o9he4nkc9gnl4ealmcdtopf158', '2025-11-11 22:37:00', NULL, NULL, '181.176.210.66', NULL),
(308, 3, 'fd9q948212q0f2n06djrod2m8d', '2025-11-12 03:01:00', NULL, NULL, '190.235.170.33', NULL),
(309, 3, '4kj9i7up82gmfkatj7ibfmj30e', '2025-11-12 14:19:46', NULL, NULL, '2001:1388:18:10e9:904:8f5f:314d:cd5a', NULL),
(310, 9, '8hvvvmf18o97h4dm7n9uqt1kda', '2025-11-12 14:25:02', NULL, NULL, '38.43.130.123', NULL),
(311, 5, '585usbigl3756go8lb56lh786b', '2025-11-12 23:04:08', '2025-11-12 23:09:12', 304, '190.119.250.33', '190.119.250.33'),
(312, 4, 'uh62dgas7p8hmcvnh619o9h756', '2025-11-13 13:45:08', NULL, NULL, '2800:200:e240:12ad:40d8:c300:cd8b:882f', NULL),
(313, 5, 'jrbg32hg8nfh65fp2aqdek7efl', '2025-11-13 15:36:58', NULL, NULL, '2803:a3e0:1731:b300:5ca1:ca72:21f8:6db8', NULL),
(314, 3, '3db1p9sr46i2hli2p9r0h2tfg4', '2025-11-13 21:37:51', NULL, NULL, '38.25.25.89', NULL),
(315, 4, 'u4ql78f2h2hii312salhjdkcvl', '2025-11-14 15:18:44', NULL, NULL, '2800:200:e240:12ad:e0c3:6b85:f15d:9b8c', NULL),
(316, 5, '8r9c8l5mamouto9ag18u6peu3r', '2025-11-15 01:06:06', '2025-11-15 01:15:56', 590, '2803:a3e0:1731:b300:3408:2a8f:7676:d8ce', '2803:a3e0:1731:b300:3408:2a8f:7676:d8ce'),
(317, 4, 'u4ql78f2h2hii312salhjdkcvl', '2025-11-17 13:23:37', NULL, NULL, '2800:200:e240:12ad:fcdd:9f5d:84d0:c498', NULL),
(318, 5, 'n7tksh40ppkptvrij028fiv513', '2025-11-17 14:10:46', NULL, NULL, '2803:a3e0:1730:a4c0:a893:31cf:bbbc:b09e', NULL),
(319, 9, 'acebtp14k817v5afo1ac8kiikq', '2025-11-17 20:31:49', NULL, NULL, '132.251.1.38', NULL),
(320, 9, '068s7siu1ot78k76dar066f7vm', '2025-11-18 22:58:34', NULL, NULL, '132.191.0.207', NULL),
(321, 3, '3db1p9sr46i2hli2p9r0h2tfg4', '2025-11-19 13:39:19', NULL, NULL, '2001:1388:18:10e9:6dc8:851b:6970:87ac', NULL),
(322, 9, 'hpla9dlofvvchuusj7i7th83of', '2025-11-20 21:17:07', NULL, NULL, '132.191.2.183', NULL),
(323, 3, 'h14kie7l6106hdicln1ehto00f', '2025-11-21 14:49:47', '2025-11-21 16:58:06', 7699, '181.176.210.66', '181.176.210.66'),
(324, 4, 'iis4ea6rkblfbjd2o1l2qgb3ou', '2025-11-21 20:01:42', NULL, NULL, '2800:200:ef40:6b:98b4:ea0b:e020:9c2d', NULL),
(325, 3, '1k52on0u50falrnlp1r1a1rj32', '2025-11-21 22:02:32', '2025-11-21 22:52:09', 2977, '181.176.210.66', '181.176.210.66'),
(326, 4, 'c0ar290hfmb32g4csjlfvuejju', '2025-11-25 13:51:57', NULL, NULL, '2800:200:e240:12ad:ad10:78c:bfcc:d48c', NULL),
(327, 9, 'd01vjerq2df2d12b7aqkvcol3d', '2025-11-25 13:57:35', NULL, NULL, '132.191.0.1', NULL),
(328, 3, '3db1p9sr46i2hli2p9r0h2tfg4', '2025-11-25 21:31:38', '2025-11-27 23:01:34', 178196, '38.25.25.89', '38.25.25.89'),
(329, 3, 'mra49hpe6tgtnlsci8cqcvki68', '2025-11-25 21:40:16', NULL, NULL, '181.176.210.66', NULL),
(330, 3, 'kr9g6qkmhdqjlqi6c6186armts', '2025-11-26 05:59:33', NULL, NULL, '190.235.170.33', NULL),
(331, 5, 'jhggqeq3o643g3in8kp97nduid', '2025-11-26 13:40:23', '2025-11-28 16:46:41', 183978, '2803:a3e0:1731:2120:9878:25f8:bc6d:43a7', '2803:a3e0:1731:2120:800d:3af:4ce0:6fa2'),
(332, 9, 'iblggg0t7vilqro4k985knc88i', '2025-11-26 13:55:01', '2025-11-28 17:43:13', 186492, '132.191.0.1', '132.191.2.145'),
(333, 3, 'sfbl059tiv1ksc2pve0ruf9klr', '2025-11-26 20:15:51', NULL, NULL, '181.176.210.66', NULL),
(334, 3, 'hg3c5v6fe1mhugj6brhi0q2e4m', '2025-11-27 03:12:07', NULL, NULL, '181.176.84.29', NULL),
(335, 3, 'ghomraesgq2lar7mif2pvptde0', '2025-11-27 12:56:44', NULL, NULL, '181.176.210.66', NULL),
(336, 3, '3kr67a1758f1iucnsqhagon17q', '2025-11-27 15:43:19', NULL, NULL, '181.176.106.30', NULL),
(337, 9, 'pmedt6bb5dh9oa1froqdv1veco', '2025-11-27 19:05:56', '2025-11-27 19:07:14', 78, '181.176.210.66', '181.176.210.66'),
(338, 4, 'soa3t262j8qpbj3gsci9ic6gla', '2025-11-27 20:21:36', NULL, NULL, '2800:200:e240:12ad:8d31:aa13:7d6f:dc43', NULL),
(339, 5, 'd6hloiiefpgt8igmnc6qhse1mt', '2025-11-27 22:28:50', '2025-11-27 22:31:31', 161, '181.176.210.66', '181.176.210.66'),
(340, 3, '02tb308g2kdcn1kppltbd6tom0', '2025-11-27 22:31:42', '2025-11-27 22:33:23', 101, '181.176.210.66', '181.176.210.66'),
(341, 5, 'o1kvjj4th1l4l2c4tb6pjh3f5t', '2025-11-27 22:33:39', '2025-11-27 22:57:43', 1444, '181.176.210.66', '181.176.210.66'),
(342, 3, 'ue3ji9fgpc11qgebmq9obpausp', '2025-11-27 22:58:08', '2025-11-28 00:01:55', 3827, '181.176.210.66', '181.176.210.66'),
(343, 4, '0hgfsglbpfps1hl5dm722c3krv', '2025-11-27 23:01:43', '2025-11-28 13:39:37', 52674, '38.25.25.89', '38.25.25.89'),
(344, 4, 'enm1kmbir9ucfokrj6d8fuq8m9', '2025-11-28 00:02:03', '2025-11-28 00:36:53', 2090, '181.176.210.66', '181.176.210.66'),
(345, 3, 'idgud0il6tn3kou0n8o8dokrco', '2025-11-28 00:37:04', '2025-11-28 00:48:07', 663, '181.176.210.66', '181.176.210.66'),
(346, 4, '99ebnli6glmfs5t6c7bjfok33c', '2025-11-28 00:38:28', NULL, NULL, '181.176.106.30', NULL),
(347, 9, '0loeq3n5tpcuf063965qrsv07g', '2025-11-28 00:49:29', '2025-11-28 00:51:05', 96, '181.176.210.66', '181.176.210.66'),
(348, 5, 'mmq9rico1pihjbjh8p85nc32h1', '2025-11-28 00:51:13', NULL, NULL, '181.176.210.66', NULL),
(349, 4, '8dvml5jjf016cv5bcde9s1letc', '2025-11-28 00:55:04', '2025-11-28 02:09:14', 4450, '181.176.210.66', '181.176.210.66'),
(350, 5, 'usg2fs7pne2k5j1b150pnosuv9', '2025-11-28 00:57:50', NULL, NULL, '181.176.106.30', NULL),
(351, 3, 'npgm8bi9vujb47avk4ouh09gcs', '2025-11-28 04:51:37', '2025-11-28 10:32:49', 20472, '190.235.170.33', '190.235.170.33'),
(352, 3, 'fte1t0kqntscsinu0gqpn5c2p2', '2025-11-28 08:10:29', '2025-11-28 10:28:00', 8251, '190.235.170.33', '190.235.170.33'),
(353, 5, '0defvp17oe081lo917f5d48svf', '2025-11-28 10:28:38', '2025-11-28 10:33:54', 316, '190.235.170.33', '190.235.170.33'),
(354, 8, '9kg4hd9jfs6etsh8kkms2kv4b8', '2025-11-28 10:33:33', '2025-11-28 10:36:35', 182, '190.235.170.33', '190.235.170.33'),
(355, 8, 'm95ilv4hp94ksgd4p5fgipcnq4', '2025-11-28 10:34:56', NULL, NULL, '190.235.170.33', NULL),
(356, 3, 'tjdtr45mvpfmcfqetue8jgjusd', '2025-11-28 10:36:48', '2025-11-28 10:44:57', 489, '190.235.170.33', '190.235.170.33'),
(357, 3, '5f6hvbbni3i0csqq32h457j2v5', '2025-11-28 12:37:59', '2025-11-28 15:10:02', 9123, '181.176.210.66', '181.176.210.66'),
(358, 3, 'bcppso9d0m5kmvn5jvjq67tbaa', '2025-11-28 13:39:43', '2025-11-28 16:48:01', 11298, '38.25.25.89', '38.25.25.89'),
(359, 4, '4pcg2gebbqrdsec1jsbk99im10', '2025-11-28 15:10:11', '2025-11-28 17:40:04', 8993, '181.176.210.66', '181.176.210.66'),
(360, 3, '6tiipeuj4oi2kriee7ea6r23e5', '2025-11-28 16:48:46', '2025-11-28 16:48:52', 6, '38.25.25.89', '38.25.25.89'),
(361, 5, 'qpveevd1uvha1i0p5jbfqvn3nc', '2025-11-28 16:49:07', '2025-11-28 16:49:58', 51, '38.25.25.89', '38.25.25.89'),
(362, 3, 'mukiuos22m9a1rjj9kqm07070i', '2025-11-28 16:50:01', NULL, NULL, '38.25.25.89', NULL),
(363, 5, '2v67k0pel670ma9k034gib50nn', '2025-11-28 16:50:35', '2025-11-28 21:05:20', 15285, '2803:a3e0:1731:2120:800d:3af:4ce0:6fa2', '2803:a3e0:1731:2120:800d:3af:4ce0:6fa2'),
(364, 9, 'p3hhl31gl6443nfrivegerlgvj', '2025-11-28 17:43:18', '2025-11-28 17:44:16', 58, '132.191.2.145', '132.191.2.145'),
(365, 4, '29eto6kg6kv5ujl8ufgplb8uao', '2025-11-28 17:43:33', NULL, NULL, '2800:200:e240:12ad:9974:f388:6e91:1656', NULL),
(366, 9, 'trv4p4tr72s7lbdnqlp0o0b0bs', '2025-11-28 17:44:23', '2025-11-28 17:48:11', 228, '132.191.2.145', '132.191.2.145'),
(367, 9, 'galrqbp6r1qi5vi4hpm20nc24o', '2025-11-28 17:48:14', NULL, NULL, '132.191.2.145', NULL),
(368, 3, 'l6ml58u55dglm55ooroot82qnm', '2025-11-28 19:15:29', NULL, NULL, '181.176.210.66', NULL),
(369, 3, 'bh36h0ohrti423in2taoqhcpur', '2025-11-28 19:54:00', NULL, NULL, '2800:4b0:5400:1735:187c:675:780f:268e', NULL),
(370, 5, 've3ar6ut5ptpuo5q4ckl32qnfa', '2025-11-28 21:05:30', NULL, NULL, '2803:a3e0:1731:2120:800d:3af:4ce0:6fa2', NULL),
(371, 3, 'tfs1nk6vn1o5v3mdugtsgm89ec', '2025-11-28 21:08:49', NULL, NULL, '2800:4b0:5400:1735:187c:675:780f:268e', NULL),
(372, 4, 'mutg2u8umv0sp50ssji40hk5sj', '2025-12-01 13:35:25', '2025-12-01 19:38:22', 21777, '2800:200:e240:12ad:35ba:9f81:807d:477f', '2800:200:e240:12ad:35ba:9f81:807d:477f'),
(373, 3, '32b3rc631jhpa61u16jmumua24', '2025-12-01 13:50:14', NULL, NULL, '38.25.25.89', NULL),
(374, 4, 'flrcocfg42v8cgr9f8iqfbdrks', '2025-12-01 19:38:25', NULL, NULL, '2800:200:e240:12ad:35ba:9f81:807d:477f', NULL),
(375, 3, 'mukiuos22m9a1rjj9kqm07070i', '2025-12-01 20:46:13', NULL, NULL, '38.25.25.89', NULL),
(376, 3, '0vo8urp92b40j8tn80fu2mf3ts', '2025-12-01 21:42:53', '2025-12-01 21:45:25', 152, '181.176.210.66', '181.176.210.66'),
(377, 5, 'rcrjb934geolbfsjk8grnaeoeq', '2025-12-01 21:45:33', '2025-12-01 22:01:02', 929, '181.176.210.66', '181.176.210.66'),
(378, 3, 'itfrfnm3gh4tsh5qqccata9sq9', '2025-12-02 03:09:22', NULL, NULL, '181.176.210.66', NULL),
(379, 8, 'peqeeqv5ogrb2sk9kovqfnigan', '2025-12-02 05:32:59', '2025-12-02 05:33:56', 57, '190.235.170.33', '190.235.170.33'),
(380, 3, 'og49rm0eb0v9reh29anq99ei9d', '2025-12-02 05:34:17', NULL, NULL, '190.235.170.33', NULL),
(381, 3, '3ebck87dlmvrtqb88lcchalgir', '2025-12-02 12:54:28', NULL, NULL, '181.176.210.66', NULL),
(382, 4, 'flrcocfg42v8cgr9f8iqfbdrks', '2025-12-02 14:07:07', NULL, NULL, '2800:200:e240:12ad:1559:a1ac:d16:4c5c', NULL),
(383, 9, 'galrqbp6r1qi5vi4hpm20nc24o', '2025-12-02 18:56:21', NULL, NULL, '132.191.2.141', NULL),
(384, 3, 'mukiuos22m9a1rjj9kqm07070i', '2025-12-02 20:29:46', NULL, NULL, '38.25.18.25', NULL),
(385, 5, 've3ar6ut5ptpuo5q4ckl32qnfa', '2025-12-02 20:53:22', NULL, NULL, '2803:a3e0:1733:7770:64e0:8412:e83a:b498', NULL),
(386, 4, 'qa0c5385c3clhpgvjl687kpnmf', '2025-12-03 14:07:08', NULL, NULL, '38.43.130.87', NULL),
(387, 4, '0v5i975nv5c6kcfut23h5bgga1', '2025-12-04 13:17:20', NULL, NULL, '2800:200:e240:12ad:20b1:60f7:5098:3443', NULL),
(388, 3, '636i1ab58ajetelqs6dtkv6puk', '2025-12-04 19:44:24', NULL, NULL, '::1', NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tema`
--

CREATE TABLE `tema` (
  `idtema` int(11) NOT NULL,
  `descripcion` varchar(500) NOT NULL,
  `idencargado` int(11) DEFAULT NULL,
  `comentario` varchar(500) NOT NULL,
  `activo` int(11) NOT NULL DEFAULT 1,
  `editor` int(11) NOT NULL DEFAULT 1,
  `registrado` int(11) NOT NULL DEFAULT current_timestamp(),
  `modificado` int(11) NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `tema`
--

INSERT INTO `tema` (`idtema`, `descripcion`, `idencargado`, `comentario`, `activo`, `editor`, `registrado`, `modificado`) VALUES
(1, 'Asesoría Legal', 4, '', 1, 2, 2147483647, 2147483647),
(2, 'Agenda Regulatoria', 12, '', 1, 2, 2147483647, 2147483647),
(3, 'Protección de Datos Personales', 4, '', 1, 2, 2147483647, 2147483647),
(4, 'Alerta Normativa', 4, '', 1, 2, 2147483647, 2147483647),
(5, 'Secreto de las Telecomunicaciones', 4, '', 1, 2, 2147483647, 2147483647),
(6, 'Condiciones de Uso | Reclamos', 4, '', 1, 1, 2147483647, 2147483647),
(7, 'Compartición de Infraestructura', 4, '', 1, 2, 2147483647, 2147483647),
(8, 'Página Web | Indicadores de Calidad de Usuario', 4, '', 1, 1, 2147483647, 2147483647),
(9, 'Otro', 9, '', 0, 2, 2147483647, 2147483647),
(10, 'Portabilidad', 4, '', 1, 1, 2147483647, 2147483647),
(11, 'CIPS | Marco Normativo de Establecimientos Penitenciarios', 4, '', 1, 1, 2147483647, 2147483647),
(12, 'Tarifas', 4, '', 1, 1, 2147483647, 2147483647),
(13, 'Uso Indebido | Uso Prohibido', 4, '', 1, 1, 2147483647, 2147483647),
(14, 'Interconexión', 3, '', 1, 2, 2147483647, 2147483647),
(15, 'OMV', 3, '', 1, 2, 2147483647, 2147483647),
(16, 'OIMR | PIP', 4, '', 1, 2, 2147483647, 2147483647),
(17, 'Contratación B2C, B2B y Mayorista', 4, '', 1, 2, 2147483647, 2147483647),
(18, 'Obligaciones de Interconexión y Acceso (Contratos y Mandatos)', 3, '', 1, 2, 2147483647, 2147483647),
(19, 'Otros', 9, '', 0, 2, 2147483647, 2147483647),
(20, 'Clasificación de Servicios', 3, '', 1, 2, 2147483647, 2147483647),
(21, 'Reglamento de Indicadores de Calidad (Velocidad Mínima)', 12, '', 1, 2, 2147483647, 2147483647),
(22, 'Normas de Emergencia (SISMATE | RECSE)', 12, '', 1, 2, 2147483647, 2147483647),
(23, 'Títulos Habilitantes', 12, '', 1, 2, 2147483647, 2147483647),
(24, 'PNAF (Espectro)', 12, '', 1, 2, 2147483647, 2147483647),
(25, 'Obligaciones Periódicas Contractuales y Normativas (NRIP | NRIS | Aportes | Secreto | Numeración | Canon | Plan de Cobertura)', 12, '', 1, 2, 2147483647, 2147483647),
(26, 'Normas de Numeración y Señalización', 12, '', 1, 2, 2147483647, 2147483647),
(27, 'Interrupciones y Devoluciones', 12, '', 1, 2, 2147483647, 2147483647),
(28, 'Neutralidad de Red', 12, '', 1, 2, 2147483647, 2147483647),
(29, 'Homologación e Internamiento de Equipos', 12, '', 1, 2, 2147483647, 2147483647),
(30, 'Obligaciones Proveedor de Capacidad Satelital (KINEIS)', 12, '', 1, 2, 2147483647, 2147483647),
(31, 'Boletín Regulatorio', 4, '', 1, 2, 2147483647, 2147483647),
(32, 'Compliance Regulatorio', 9, '', 1, 2, 2147483647, 2147483647),
(33, 'Obligaciones Económicas', 3, '', 1, 2, 2147483647, 2147483647),
(34, 'Normas Ambientales (SEIA)', 4, '', 1, 2, 2147483647, 2147483647),
(35, 'Norma de Metodología de Cálculo de Sanciones OSIPTEL (Cálculo)', 12, '', 1, 2, 2147483647, 2147483647),
(36, 'Mapa de Obligaciones', 3, '', 1, 2, 2147483647, 2147483647),
(37, 'RNI', 12, '', 1, 2, 2147483647, 2147483647),
(38, 'RENTESEG', 12, '', 1, 2, 2147483647, 2147483647);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `trigger_debug_log`
--

CREATE TABLE `trigger_debug_log` (
  `log_id` int(11) NOT NULL,
  `trigger_name` varchar(50) DEFAULT NULL,
  `log_timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  `message` varchar(255) DEFAULT NULL,
  `idliquidacion_val` int(11) DEFAULT NULL,
  `iddetalle_val` int(11) DEFAULT NULL,
  `estado_val` varchar(50) DEFAULT NULL,
  `planificacion_id_val` int(11) DEFAULT NULL,
  `distribucionhora_count` int(11) DEFAULT NULL,
  `insert_attempted` tinyint(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `trigger_debug_log`
--

INSERT INTO `trigger_debug_log` (`log_id`, `trigger_name`, `log_timestamp`, `message`, `idliquidacion_val`, `iddetalle_val`, `estado_val`, `planificacion_id_val`, `distribucionhora_count`, `insert_attempted`) VALUES
(1, 'insert', '2025-07-19 06:42:50', 'Trigger START', 76, NULL, 'Completo', NULL, NULL, NULL),
(2, 'insert', '2025-07-19 06:42:50', 'After Planificacion SELECT', 76, NULL, NULL, 6, NULL, NULL),
(3, 'insert', '2025-07-19 06:42:50', 'After detalles_planificacion INSERT', 76, 128, 'Completo', NULL, NULL, NULL),
(4, 'insert', '2025-07-19 06:42:50', 'CONDITION MET for distrib_planif', 76, 128, 'Completo', NULL, NULL, 0),
(5, 'insert', '2025-07-19 06:42:50', 'Count from distribucionhora', 76, NULL, NULL, NULL, 0, NULL),
(6, 'insert', '2025-07-19 06:42:50', 'Skipped INSERT (no rows in distribucionhora)', 76, NULL, NULL, NULL, 0, 0),
(7, 'insert', '2025-07-19 06:42:50', 'Trigger END', 76, NULL, NULL, NULL, NULL, NULL),
(8, 'insert', '2025-07-21 13:25:31', 'Trigger START', 77, NULL, 'En proceso', NULL, NULL, NULL),
(9, 'insert', '2025-07-21 13:25:31', 'After Planificacion SELECT', 77, NULL, NULL, NULL, NULL, NULL),
(10, 'insert', '2025-07-21 13:25:31', 'v_idplanificacion IS NULL', 77, NULL, NULL, NULL, NULL, 0),
(11, 'insert', '2025-07-21 13:25:31', 'Trigger END', 77, NULL, NULL, NULL, NULL, NULL),
(12, 'insert', '2025-07-21 13:29:30', 'Trigger START', 78, NULL, 'En revisión', NULL, NULL, NULL),
(13, 'insert', '2025-07-21 13:29:30', 'After Planificacion SELECT', 78, NULL, NULL, 10, NULL, NULL),
(14, 'insert', '2025-07-21 13:29:30', 'After detalles_planificacion INSERT', 78, 129, 'En revisión', NULL, NULL, NULL),
(15, 'insert', '2025-07-21 13:29:30', 'CONDITION NOT MET for distrib_planif', 78, 129, 'En revisión', NULL, NULL, 0),
(16, 'insert', '2025-07-21 13:29:30', 'Trigger END', 78, NULL, NULL, NULL, NULL, NULL),
(17, 'insert', '2025-07-21 13:31:19', 'Trigger START', 79, NULL, 'Programado', NULL, NULL, NULL),
(18, 'insert', '2025-07-21 13:31:19', 'After Planificacion SELECT', 79, NULL, NULL, 10, NULL, NULL),
(19, 'insert', '2025-07-21 13:31:19', 'After detalles_planificacion INSERT', 79, 130, 'Programado', NULL, NULL, NULL),
(20, 'insert', '2025-07-21 13:31:19', 'CONDITION NOT MET for distrib_planif', 79, 130, 'Programado', NULL, NULL, 0),
(21, 'insert', '2025-07-21 13:31:19', 'Trigger END', 79, NULL, NULL, NULL, NULL, NULL),
(22, 'insert', '2025-07-21 13:47:22', 'Trigger START', 80, NULL, 'Programado', NULL, NULL, NULL),
(23, 'insert', '2025-07-21 13:47:22', 'After Planificacion SELECT', 80, NULL, NULL, 10, NULL, NULL),
(24, 'insert', '2025-07-21 13:47:22', 'After detalles_planificacion INSERT', 80, 131, 'Programado', NULL, NULL, NULL),
(25, 'insert', '2025-07-21 13:47:22', 'CONDITION NOT MET for distrib_planif', 80, 131, 'Programado', NULL, NULL, 0),
(26, 'insert', '2025-07-21 13:47:22', 'Trigger END', 80, NULL, NULL, NULL, NULL, NULL),
(27, 'insert', '2025-07-21 13:56:23', 'Trigger START', 81, NULL, 'Programado', NULL, NULL, NULL),
(28, 'insert', '2025-07-21 13:56:23', 'After Planificacion SELECT', 81, NULL, NULL, 10, NULL, NULL),
(29, 'insert', '2025-07-21 13:56:23', 'After detalles_planificacion INSERT', 81, 132, 'Programado', NULL, NULL, NULL),
(30, 'insert', '2025-07-21 13:56:23', 'CONDITION NOT MET for distrib_planif', 81, 132, 'Programado', NULL, NULL, 0),
(31, 'insert', '2025-07-21 13:56:23', 'Trigger END', 81, NULL, NULL, NULL, NULL, NULL),
(32, 'insert', '2025-07-21 14:00:25', 'Trigger START', 82, NULL, 'Completo', NULL, NULL, NULL),
(33, 'insert', '2025-07-21 14:00:25', 'After Planificacion SELECT', 82, NULL, NULL, 10, NULL, NULL),
(34, 'insert', '2025-07-21 14:00:25', 'After detalles_planificacion INSERT', 82, 133, 'Completo', NULL, NULL, NULL),
(35, 'insert', '2025-07-21 14:00:25', 'CONDITION MET for distrib_planif', 82, 133, 'Completo', NULL, NULL, 0),
(36, 'insert', '2025-07-21 14:00:25', 'Count from distribucionhora', 82, NULL, NULL, NULL, 0, NULL),
(37, 'insert', '2025-07-21 14:00:25', 'Skipped INSERT (no rows in distribucionhora)', 82, NULL, NULL, NULL, 0, 0),
(38, 'insert', '2025-07-21 14:00:25', 'Trigger END', 82, NULL, NULL, NULL, NULL, NULL),
(39, 'insert', '2025-07-21 14:08:01', 'Trigger START', 83, NULL, 'Programado', NULL, NULL, NULL),
(40, 'insert', '2025-07-21 14:08:01', 'After Planificacion SELECT', 83, NULL, NULL, 11, NULL, NULL),
(41, 'insert', '2025-07-21 14:08:01', 'After detalles_planificacion INSERT', 83, 134, 'Programado', NULL, NULL, NULL),
(42, 'insert', '2025-07-21 14:08:01', 'CONDITION NOT MET for distrib_planif', 83, 134, 'Programado', NULL, NULL, 0),
(43, 'insert', '2025-07-21 14:08:01', 'Trigger END', 83, NULL, NULL, NULL, NULL, NULL),
(44, 'insert', '2025-07-21 14:30:31', 'Trigger START', 84, NULL, 'Programado', NULL, NULL, NULL),
(45, 'insert', '2025-07-21 14:30:31', 'After Planificacion SELECT', 84, NULL, NULL, 8, NULL, NULL),
(46, 'insert', '2025-07-21 14:30:31', 'After detalles_planificacion INSERT', 84, 135, 'Programado', NULL, NULL, NULL),
(47, 'insert', '2025-07-21 14:30:31', 'CONDITION NOT MET for distrib_planif', 84, 135, 'Programado', NULL, NULL, 0),
(48, 'insert', '2025-07-21 14:30:31', 'Trigger END', 84, NULL, NULL, NULL, NULL, NULL),
(49, 'insert', '2025-07-21 15:23:40', 'Trigger START', 85, NULL, 'Completo', NULL, NULL, NULL),
(50, 'insert', '2025-07-21 15:23:40', 'After Planificacion SELECT', 85, NULL, NULL, 6, NULL, NULL),
(51, 'insert', '2025-07-21 15:23:40', 'After detalles_planificacion INSERT', 85, 136, 'Completo', NULL, NULL, NULL),
(52, 'insert', '2025-07-21 15:23:40', 'CONDITION MET for distrib_planif', 85, 136, 'Completo', NULL, NULL, 0),
(53, 'insert', '2025-07-21 15:23:40', 'Count from distribucionhora', 85, NULL, NULL, NULL, 0, NULL),
(54, 'insert', '2025-07-21 15:23:40', 'Skipped INSERT (no rows in distribucionhora)', 85, NULL, NULL, NULL, 0, 0),
(55, 'insert', '2025-07-21 15:23:40', 'Trigger END', 85, NULL, NULL, NULL, NULL, NULL),
(56, 'insert', '2025-07-21 18:10:33', 'Trigger START', 86, NULL, 'Programado', NULL, NULL, NULL),
(57, 'insert', '2025-07-21 18:10:33', 'After Planificacion SELECT', 86, NULL, NULL, 7, NULL, NULL),
(58, 'insert', '2025-07-21 18:10:33', 'After detalles_planificacion INSERT', 86, 137, 'Programado', NULL, NULL, NULL),
(59, 'insert', '2025-07-21 18:10:33', 'CONDITION NOT MET for distrib_planif', 86, 137, 'Programado', NULL, NULL, 0),
(60, 'insert', '2025-07-21 18:10:33', 'Trigger END', 86, NULL, NULL, NULL, NULL, NULL),
(61, 'insert', '2025-07-22 15:38:29', 'Trigger START', 87, NULL, 'Completo', NULL, NULL, NULL),
(62, 'insert', '2025-07-22 15:38:29', 'After Planificacion SELECT', 87, NULL, NULL, 8, NULL, NULL),
(63, 'insert', '2025-07-22 15:38:29', 'After detalles_planificacion INSERT', 87, 138, 'Completo', NULL, NULL, NULL),
(64, 'insert', '2025-07-22 15:38:29', 'CONDITION MET for distrib_planif', 87, 138, 'Completo', NULL, NULL, 0),
(65, 'insert', '2025-07-22 15:38:29', 'Count from distribucionhora', 87, NULL, NULL, NULL, 0, NULL),
(66, 'insert', '2025-07-22 15:38:29', 'Skipped INSERT (no rows in distribucionhora)', 87, NULL, NULL, NULL, 0, 0),
(67, 'insert', '2025-07-22 15:38:29', 'Trigger END', 87, NULL, NULL, NULL, NULL, NULL),
(68, 'insert', '2025-07-24 03:25:18', 'Trigger START', 88, NULL, 'En revisión', NULL, NULL, NULL),
(69, 'insert', '2025-07-24 03:25:18', 'After Planificacion SELECT', 88, NULL, NULL, 5, NULL, NULL),
(70, 'insert', '2025-07-24 03:25:18', 'After detalles_planificacion INSERT', 88, 140, 'En revisión', NULL, NULL, NULL),
(71, 'insert', '2025-07-24 03:25:18', 'CONDITION NOT MET for distrib_planif', 88, 140, 'En revisión', NULL, NULL, 0),
(72, 'insert', '2025-07-24 03:25:18', 'Trigger END', 88, NULL, NULL, NULL, NULL, NULL),
(73, 'insert', '2025-07-24 03:29:08', 'Trigger START', 89, NULL, 'En proceso', NULL, NULL, NULL),
(74, 'insert', '2025-07-24 03:29:08', 'After Planificacion SELECT', 89, NULL, NULL, 7, NULL, NULL),
(75, 'insert', '2025-07-24 03:29:08', 'After detalles_planificacion INSERT', 89, 141, 'En proceso', NULL, NULL, NULL),
(76, 'insert', '2025-07-24 03:29:08', 'CONDITION NOT MET for distrib_planif', 89, 141, 'En proceso', NULL, NULL, 0),
(77, 'insert', '2025-07-24 03:29:08', 'Trigger END', 89, NULL, NULL, NULL, NULL, NULL),
(78, 'insert', '2025-07-24 16:57:02', 'Trigger START', 90, NULL, 'Completo', NULL, NULL, NULL),
(79, 'insert', '2025-07-24 16:57:02', 'After Planificacion SELECT', 90, NULL, NULL, 11, NULL, NULL),
(80, 'insert', '2025-07-24 16:57:02', 'After detalles_planificacion INSERT', 90, 142, 'Completo', NULL, NULL, NULL),
(81, 'insert', '2025-07-24 16:57:02', 'CONDITION MET for distrib_planif', 90, 142, 'Completo', NULL, NULL, 0),
(82, 'insert', '2025-07-24 16:57:02', 'Count from distribucionhora', 90, NULL, NULL, NULL, 0, NULL),
(83, 'insert', '2025-07-24 16:57:02', 'Skipped INSERT (no rows in distribucionhora)', 90, NULL, NULL, NULL, 0, 0),
(84, 'insert', '2025-07-24 16:57:02', 'Trigger END', 90, NULL, NULL, NULL, NULL, NULL),
(85, 'insert', '2025-07-25 19:25:35', 'Trigger START', 91, NULL, 'Completo', NULL, NULL, NULL),
(86, 'insert', '2025-07-25 19:25:35', 'After Planificacion SELECT', 91, NULL, NULL, NULL, NULL, NULL),
(87, 'insert', '2025-07-25 19:25:35', 'v_idplanificacion IS NULL', 91, NULL, NULL, NULL, NULL, 0),
(88, 'insert', '2025-07-25 19:25:35', 'Trigger END', 91, NULL, NULL, NULL, NULL, NULL),
(89, 'insert', '2025-07-31 15:11:37', 'Trigger START', 92, NULL, 'Completo', NULL, NULL, NULL),
(90, 'insert', '2025-07-31 15:11:37', 'After Planificacion SELECT', 92, NULL, NULL, NULL, NULL, NULL),
(91, 'insert', '2025-07-31 15:11:37', 'v_idplanificacion IS NULL', 92, NULL, NULL, NULL, NULL, 0),
(92, 'insert', '2025-07-31 15:11:37', 'Trigger END', 92, NULL, NULL, NULL, NULL, NULL),
(93, 'insert', '2025-07-31 15:13:13', 'Trigger START', 93, NULL, 'Completo', NULL, NULL, NULL),
(94, 'insert', '2025-07-31 15:13:13', 'After Planificacion SELECT', 93, NULL, NULL, 8, NULL, NULL),
(95, 'insert', '2025-07-31 15:13:13', 'After detalles_planificacion INSERT', 93, 144, 'Completo', NULL, NULL, NULL),
(96, 'insert', '2025-07-31 15:13:13', 'CONDITION MET for distrib_planif', 93, 144, 'Completo', NULL, NULL, 0),
(97, 'insert', '2025-07-31 15:13:13', 'Count from distribucionhora', 93, NULL, NULL, NULL, 0, NULL),
(98, 'insert', '2025-07-31 15:13:13', 'Skipped INSERT (no rows in distribucionhora)', 93, NULL, NULL, NULL, 0, 0),
(99, 'insert', '2025-07-31 15:13:13', 'Trigger END', 93, NULL, NULL, NULL, NULL, NULL),
(100, 'insert', '2025-07-31 15:16:09', 'Trigger START', 94, NULL, 'En proceso', NULL, NULL, NULL),
(101, 'insert', '2025-07-31 15:16:09', 'After Planificacion SELECT', 94, NULL, NULL, 10, NULL, NULL),
(102, 'insert', '2025-07-31 15:16:09', 'After detalles_planificacion INSERT', 94, 145, 'En proceso', NULL, NULL, NULL),
(103, 'insert', '2025-07-31 15:16:09', 'CONDITION NOT MET for distrib_planif', 94, 145, 'En proceso', NULL, NULL, 0),
(104, 'insert', '2025-07-31 15:16:09', 'Trigger END', 94, NULL, NULL, NULL, NULL, NULL),
(105, 'insert', '2025-07-31 15:17:26', 'Trigger START', 95, NULL, 'Completo', NULL, NULL, NULL),
(106, 'insert', '2025-07-31 15:17:26', 'After Planificacion SELECT', 95, NULL, NULL, 10, NULL, NULL),
(107, 'insert', '2025-07-31 15:17:26', 'After detalles_planificacion INSERT', 95, 146, 'Completo', NULL, NULL, NULL),
(108, 'insert', '2025-07-31 15:17:26', 'CONDITION MET for distrib_planif', 95, 146, 'Completo', NULL, NULL, 0),
(109, 'insert', '2025-07-31 15:17:26', 'Count from distribucionhora', 95, NULL, NULL, NULL, 0, NULL),
(110, 'insert', '2025-07-31 15:17:26', 'Skipped INSERT (no rows in distribucionhora)', 95, NULL, NULL, NULL, 0, 0),
(111, 'insert', '2025-07-31 15:17:26', 'Trigger END', 95, NULL, NULL, NULL, NULL, NULL),
(112, 'insert', '2025-07-31 22:29:39', 'Trigger START', 96, NULL, 'Completo', NULL, NULL, NULL),
(113, 'insert', '2025-07-31 22:29:39', 'After Planificacion SELECT', 96, NULL, NULL, NULL, NULL, NULL),
(114, 'insert', '2025-07-31 22:29:39', 'v_idplanificacion IS NULL', 96, NULL, NULL, NULL, NULL, 0),
(115, 'insert', '2025-07-31 22:29:39', 'Trigger END', 96, NULL, NULL, NULL, NULL, NULL),
(116, 'insert', '2025-07-31 22:59:43', 'Trigger START', 97, NULL, 'En proceso', NULL, NULL, NULL),
(117, 'insert', '2025-07-31 22:59:43', 'After Planificacion SELECT', 97, NULL, NULL, 12, NULL, NULL),
(118, 'insert', '2025-07-31 22:59:43', 'After detalles_planificacion INSERT', 97, 147, 'En proceso', NULL, NULL, NULL),
(119, 'insert', '2025-07-31 22:59:43', 'CONDITION NOT MET for distrib_planif', 97, 147, 'En proceso', NULL, NULL, 0),
(120, 'insert', '2025-07-31 22:59:43', 'Trigger END', 97, NULL, NULL, NULL, NULL, NULL),
(121, 'insert', '2025-07-31 23:19:21', 'Trigger START', 98, NULL, 'Completo', NULL, NULL, NULL),
(122, 'insert', '2025-07-31 23:19:21', 'After Planificacion SELECT', 98, NULL, NULL, 8, NULL, NULL),
(123, 'insert', '2025-07-31 23:19:21', 'After detalles_planificacion INSERT', 98, 148, 'Completo', NULL, NULL, NULL),
(124, 'insert', '2025-07-31 23:19:21', 'CONDITION MET for distrib_planif', 98, 148, 'Completo', NULL, NULL, 0),
(125, 'insert', '2025-07-31 23:19:21', 'Count from distribucionhora', 98, NULL, NULL, NULL, 0, NULL),
(126, 'insert', '2025-07-31 23:19:21', 'Skipped INSERT (no rows in distribucionhora)', 98, NULL, NULL, NULL, 0, 0),
(127, 'insert', '2025-07-31 23:19:21', 'Trigger END', 98, NULL, NULL, NULL, NULL, NULL),
(128, 'insert', '2025-08-01 17:09:00', 'Trigger START', 99, NULL, 'Completo', NULL, NULL, NULL),
(129, 'insert', '2025-08-01 17:09:00', 'After Planificacion SELECT', 99, NULL, NULL, NULL, NULL, NULL),
(130, 'insert', '2025-08-01 17:09:00', 'v_idplanificacion IS NULL', 99, NULL, NULL, NULL, NULL, 0),
(131, 'insert', '2025-08-01 17:09:00', 'Trigger END', 99, NULL, NULL, NULL, NULL, NULL),
(132, 'insert', '2025-08-01 18:40:51', 'Trigger START', 100, NULL, 'Completo', NULL, NULL, NULL),
(133, 'insert', '2025-08-01 18:40:51', 'After Planificacion SELECT', 100, NULL, NULL, 14, NULL, NULL),
(134, 'insert', '2025-08-01 18:40:51', 'After detalles_planificacion INSERT', 100, 149, 'Completo', NULL, NULL, NULL),
(135, 'insert', '2025-08-01 18:40:51', 'CONDITION MET for distrib_planif', 100, 149, 'Completo', NULL, NULL, 0),
(136, 'insert', '2025-08-01 18:40:51', 'Count from distribucionhora', 100, NULL, NULL, NULL, 0, NULL),
(137, 'insert', '2025-08-01 18:40:51', 'Skipped INSERT (no rows in distribucionhora)', 100, NULL, NULL, NULL, 0, 0),
(138, 'insert', '2025-08-01 18:40:51', 'Trigger END', 100, NULL, NULL, NULL, NULL, NULL),
(139, 'insert', '2025-08-04 13:44:13', 'Trigger START', 101, NULL, 'Programado', NULL, NULL, NULL),
(140, 'insert', '2025-08-04 13:44:13', 'After Planificacion SELECT', 101, NULL, NULL, NULL, NULL, NULL),
(141, 'insert', '2025-08-04 13:44:13', 'v_idplanificacion IS NULL', 101, NULL, NULL, NULL, NULL, 0),
(142, 'insert', '2025-08-04 13:44:13', 'Trigger END', 101, NULL, NULL, NULL, NULL, NULL),
(143, 'insert', '2025-08-04 13:46:16', 'Trigger START', 102, NULL, 'En proceso', NULL, NULL, NULL),
(144, 'insert', '2025-08-04 13:46:16', 'After Planificacion SELECT', 102, NULL, NULL, NULL, NULL, NULL),
(145, 'insert', '2025-08-04 13:46:16', 'v_idplanificacion IS NULL', 102, NULL, NULL, NULL, NULL, 0),
(146, 'insert', '2025-08-04 13:46:16', 'Trigger END', 102, NULL, NULL, NULL, NULL, NULL),
(147, 'insert', '2025-08-04 13:48:07', 'Trigger START', 103, NULL, 'Programado', NULL, NULL, NULL),
(148, 'insert', '2025-08-04 13:48:07', 'After Planificacion SELECT', 103, NULL, NULL, NULL, NULL, NULL),
(149, 'insert', '2025-08-04 13:48:07', 'v_idplanificacion IS NULL', 103, NULL, NULL, NULL, NULL, 0),
(150, 'insert', '2025-08-04 13:48:07', 'Trigger END', 103, NULL, NULL, NULL, NULL, NULL),
(151, 'insert', '2025-08-04 13:51:55', 'Trigger START', 104, NULL, 'En proceso', NULL, NULL, NULL),
(152, 'insert', '2025-08-04 13:51:55', 'After Planificacion SELECT', 104, NULL, NULL, NULL, NULL, NULL),
(153, 'insert', '2025-08-04 13:51:55', 'v_idplanificacion IS NULL', 104, NULL, NULL, NULL, NULL, 0),
(154, 'insert', '2025-08-04 13:51:55', 'Trigger END', 104, NULL, NULL, NULL, NULL, NULL),
(155, 'insert', '2025-08-08 20:29:43', 'Trigger START', 105, NULL, 'Programado', NULL, NULL, NULL),
(156, 'insert', '2025-08-08 20:29:43', 'After Planificacion SELECT', 105, NULL, NULL, NULL, NULL, NULL),
(157, 'insert', '2025-08-08 20:29:43', 'v_idplanificacion IS NULL', 105, NULL, NULL, NULL, NULL, 0),
(158, 'insert', '2025-08-08 20:29:43', 'Trigger END', 105, NULL, NULL, NULL, NULL, NULL),
(159, 'insert', '2025-08-08 21:23:16', 'Trigger START', 106, NULL, 'Completo', NULL, NULL, NULL),
(160, 'insert', '2025-08-08 21:23:16', 'After Planificacion SELECT', 106, NULL, NULL, NULL, NULL, NULL),
(161, 'insert', '2025-08-08 21:23:16', 'v_idplanificacion IS NULL', 106, NULL, NULL, NULL, NULL, 0),
(162, 'insert', '2025-08-08 21:23:16', 'Trigger END', 106, NULL, NULL, NULL, NULL, NULL),
(163, 'insert', '2025-08-08 21:25:30', 'Trigger START', 107, NULL, 'Completo', NULL, NULL, NULL),
(164, 'insert', '2025-08-08 21:25:30', 'After Planificacion SELECT', 107, NULL, NULL, NULL, NULL, NULL),
(165, 'insert', '2025-08-08 21:25:30', 'v_idplanificacion IS NULL', 107, NULL, NULL, NULL, NULL, 0),
(166, 'insert', '2025-08-08 21:25:30', 'Trigger END', 107, NULL, NULL, NULL, NULL, NULL),
(167, 'insert', '2025-08-08 21:32:15', 'Trigger START', 108, NULL, 'Completo', NULL, NULL, NULL),
(168, 'insert', '2025-08-08 21:32:15', 'After Planificacion SELECT', 108, NULL, NULL, NULL, NULL, NULL),
(169, 'insert', '2025-08-08 21:32:15', 'v_idplanificacion IS NULL', 108, NULL, NULL, NULL, NULL, 0),
(170, 'insert', '2025-08-08 21:32:15', 'Trigger END', 108, NULL, NULL, NULL, NULL, NULL),
(171, 'insert', '2025-08-08 21:43:26', 'Trigger START', 109, NULL, 'Completo', NULL, NULL, NULL),
(172, 'insert', '2025-08-08 21:43:26', 'After Planificacion SELECT', 109, NULL, NULL, 15, NULL, NULL),
(173, 'insert', '2025-08-08 21:43:26', 'After detalles_planificacion INSERT', 109, 151, 'Completo', NULL, NULL, NULL),
(174, 'insert', '2025-08-08 21:43:26', 'CONDITION MET for distrib_planif', 109, 151, 'Completo', NULL, NULL, 0),
(175, 'insert', '2025-08-08 21:43:26', 'Count from distribucionhora', 109, NULL, NULL, NULL, 0, NULL),
(176, 'insert', '2025-08-08 21:43:26', 'Skipped INSERT (no rows in distribucionhora)', 109, NULL, NULL, NULL, 0, 0),
(177, 'insert', '2025-08-08 21:43:26', 'Trigger END', 109, NULL, NULL, NULL, NULL, NULL),
(178, 'insert', '2025-08-11 21:45:49', 'Trigger START', 110, NULL, 'Completo', NULL, NULL, NULL),
(179, 'insert', '2025-08-11 21:45:49', 'After Planificacion SELECT', 110, NULL, NULL, NULL, NULL, NULL),
(180, 'insert', '2025-08-11 21:45:49', 'v_idplanificacion IS NULL', 110, NULL, NULL, NULL, NULL, 0),
(181, 'insert', '2025-08-11 21:45:49', 'Trigger END', 110, NULL, NULL, NULL, NULL, NULL),
(182, 'insert', '2025-08-12 21:33:54', 'Trigger START', 111, NULL, 'Completo', NULL, NULL, NULL),
(183, 'insert', '2025-08-12 21:33:54', 'After Planificacion SELECT', 111, NULL, NULL, NULL, NULL, NULL),
(184, 'insert', '2025-08-12 21:33:54', 'v_idplanificacion IS NULL', 111, NULL, NULL, NULL, NULL, 0),
(185, 'insert', '2025-08-12 21:33:54', 'Trigger END', 111, NULL, NULL, NULL, NULL, NULL),
(186, 'insert', '2025-08-12 22:09:47', 'Trigger START', 112, NULL, 'En proceso', NULL, NULL, NULL),
(187, 'insert', '2025-08-12 22:09:47', 'After Planificacion SELECT', 112, NULL, NULL, NULL, NULL, NULL),
(188, 'insert', '2025-08-12 22:09:47', 'v_idplanificacion IS NULL', 112, NULL, NULL, NULL, NULL, 0),
(189, 'insert', '2025-08-12 22:09:47', 'Trigger END', 112, NULL, NULL, NULL, NULL, NULL),
(190, 'insert', '2025-08-12 22:31:08', 'Trigger START', 113, NULL, 'Completo', NULL, NULL, NULL),
(191, 'insert', '2025-08-12 22:31:08', 'After Planificacion SELECT', 113, NULL, NULL, NULL, NULL, NULL),
(192, 'insert', '2025-08-12 22:31:08', 'v_idplanificacion IS NULL', 113, NULL, NULL, NULL, NULL, 0),
(193, 'insert', '2025-08-12 22:31:08', 'Trigger END', 113, NULL, NULL, NULL, NULL, NULL),
(194, 'insert', '2025-08-13 16:54:27', 'Trigger START', 114, NULL, 'Completo', NULL, NULL, NULL),
(195, 'insert', '2025-08-13 16:54:27', 'After Planificacion SELECT', 114, NULL, NULL, 16, NULL, NULL),
(196, 'insert', '2025-08-13 16:54:27', 'After detalles_planificacion INSERT', 114, 154, 'Completo', NULL, NULL, NULL),
(197, 'insert', '2025-08-13 16:54:27', 'CONDITION MET for distrib_planif', 114, 154, 'Completo', NULL, NULL, 0),
(198, 'insert', '2025-08-13 16:54:27', 'Count from distribucionhora', 114, NULL, NULL, NULL, 0, NULL),
(199, 'insert', '2025-08-13 16:54:27', 'Skipped INSERT (no rows in distribucionhora)', 114, NULL, NULL, NULL, 0, 0),
(200, 'insert', '2025-08-13 16:54:27', 'Trigger END', 114, NULL, NULL, NULL, NULL, NULL),
(201, 'insert', '2025-08-14 17:30:50', 'Trigger START', 115, NULL, 'Completo', NULL, NULL, NULL),
(202, 'insert', '2025-08-14 17:30:50', 'After Planificacion SELECT', 115, NULL, NULL, 15, NULL, NULL),
(203, 'insert', '2025-08-14 17:30:50', 'After detalles_planificacion INSERT', 115, 170, 'Completo', NULL, NULL, NULL),
(204, 'insert', '2025-08-14 17:30:50', 'CONDITION MET for distrib_planif', 115, 170, 'Completo', NULL, NULL, 0),
(205, 'insert', '2025-08-14 17:30:50', 'Count from distribucionhora', 115, NULL, NULL, NULL, 0, NULL),
(206, 'insert', '2025-08-14 17:30:50', 'Skipped INSERT (no rows in distribucionhora)', 115, NULL, NULL, NULL, 0, 0),
(207, 'insert', '2025-08-14 17:30:50', 'Trigger END', 115, NULL, NULL, NULL, NULL, NULL),
(208, 'insert', '2025-08-15 22:45:18', 'Trigger START', 116, NULL, 'Completo', NULL, NULL, NULL),
(209, 'insert', '2025-08-15 22:45:18', 'After Planificacion SELECT', 116, NULL, NULL, 20, NULL, NULL),
(210, 'insert', '2025-08-15 22:45:18', 'After detalles_planificacion INSERT', 116, 171, 'Completo', NULL, NULL, NULL),
(211, 'insert', '2025-08-15 22:45:18', 'CONDITION MET for distrib_planif', 116, 171, 'Completo', NULL, NULL, 0),
(212, 'insert', '2025-08-15 22:45:18', 'Count from distribucionhora', 116, NULL, NULL, NULL, 0, NULL),
(213, 'insert', '2025-08-15 22:45:18', 'Skipped INSERT (no rows in distribucionhora)', 116, NULL, NULL, NULL, 0, 0),
(214, 'insert', '2025-08-15 22:45:18', 'Trigger END', 116, NULL, NULL, NULL, NULL, NULL),
(215, 'insert', '2025-08-15 23:57:31', 'Trigger START', 117, NULL, 'Completo', NULL, NULL, NULL),
(216, 'insert', '2025-08-15 23:57:31', 'After Planificacion SELECT', 117, NULL, NULL, 19, NULL, NULL),
(217, 'insert', '2025-08-15 23:57:31', 'After detalles_planificacion INSERT', 117, 172, 'Completo', NULL, NULL, NULL),
(218, 'insert', '2025-08-15 23:57:31', 'CONDITION MET for distrib_planif', 117, 172, 'Completo', NULL, NULL, 0),
(219, 'insert', '2025-08-15 23:57:31', 'Count from distribucionhora', 117, NULL, NULL, NULL, 0, NULL),
(220, 'insert', '2025-08-15 23:57:31', 'Skipped INSERT (no rows in distribucionhora)', 117, NULL, NULL, NULL, 0, 0),
(221, 'insert', '2025-08-15 23:57:31', 'Trigger END', 117, NULL, NULL, NULL, NULL, NULL),
(222, 'insert', '2025-08-16 00:05:19', 'Trigger START', 118, NULL, 'Completo', NULL, NULL, NULL),
(223, 'insert', '2025-08-16 00:05:19', 'After Planificacion SELECT', 118, NULL, NULL, 19, NULL, NULL),
(224, 'insert', '2025-08-16 00:05:19', 'After detalles_planificacion INSERT', 118, 173, 'Completo', NULL, NULL, NULL),
(225, 'insert', '2025-08-16 00:05:19', 'CONDITION MET for distrib_planif', 118, 173, 'Completo', NULL, NULL, 0),
(226, 'insert', '2025-08-16 00:05:19', 'Count from distribucionhora', 118, NULL, NULL, NULL, 0, NULL),
(227, 'insert', '2025-08-16 00:05:19', 'Skipped INSERT (no rows in distribucionhora)', 118, NULL, NULL, NULL, 0, 0),
(228, 'insert', '2025-08-16 00:05:19', 'Trigger END', 118, NULL, NULL, NULL, NULL, NULL),
(229, 'insert', '2025-08-16 01:24:51', 'Trigger START', 119, NULL, 'Completo', NULL, NULL, NULL),
(230, 'insert', '2025-08-16 01:24:51', 'After Planificacion SELECT', 119, NULL, NULL, 17, NULL, NULL),
(231, 'insert', '2025-08-16 01:24:51', 'After detalles_planificacion INSERT', 119, 174, 'Completo', NULL, NULL, NULL),
(232, 'insert', '2025-08-16 01:24:51', 'CONDITION MET for distrib_planif', 119, 174, 'Completo', NULL, NULL, 0),
(233, 'insert', '2025-08-16 01:24:51', 'Count from distribucionhora', 119, NULL, NULL, NULL, 0, NULL),
(234, 'insert', '2025-08-16 01:24:51', 'Skipped INSERT (no rows in distribucionhora)', 119, NULL, NULL, NULL, 0, 0),
(235, 'insert', '2025-08-16 01:24:51', 'Trigger END', 119, NULL, NULL, NULL, NULL, NULL),
(236, 'insert', '2025-08-18 21:55:53', 'Trigger START', 120, NULL, 'En revisión', NULL, NULL, NULL),
(237, 'insert', '2025-08-18 21:55:53', 'After Planificacion SELECT', 120, NULL, NULL, 16, NULL, NULL),
(238, 'insert', '2025-08-18 21:55:53', 'After detalles_planificacion INSERT', 120, 175, 'En revisión', NULL, NULL, NULL),
(239, 'insert', '2025-08-18 21:55:53', 'CONDITION NOT MET for distrib_planif', 120, 175, 'En revisión', NULL, NULL, 0),
(240, 'insert', '2025-08-18 21:55:53', 'Trigger END', 120, NULL, NULL, NULL, NULL, NULL),
(241, 'insert', '2025-08-18 22:01:43', 'Trigger START', 121, NULL, 'Programado', NULL, NULL, NULL),
(242, 'insert', '2025-08-18 22:01:43', 'After Planificacion SELECT', 121, NULL, NULL, 21, NULL, NULL),
(243, 'insert', '2025-08-18 22:01:43', 'After detalles_planificacion INSERT', 121, 176, 'Programado', NULL, NULL, NULL),
(244, 'insert', '2025-08-18 22:01:43', 'CONDITION NOT MET for distrib_planif', 121, 176, 'Programado', NULL, NULL, 0),
(245, 'insert', '2025-08-18 22:01:43', 'Trigger END', 121, NULL, NULL, NULL, NULL, NULL),
(246, 'insert', '2025-08-19 20:12:00', 'Trigger START', 122, NULL, 'Completo', NULL, NULL, NULL),
(247, 'insert', '2025-08-19 20:12:00', 'After Planificacion SELECT', 122, NULL, NULL, 20, NULL, NULL),
(248, 'insert', '2025-08-19 20:12:00', 'After detalles_planificacion INSERT', 122, 177, 'Completo', NULL, NULL, NULL),
(249, 'insert', '2025-08-19 20:12:00', 'CONDITION MET for distrib_planif', 122, 177, 'Completo', NULL, NULL, 0),
(250, 'insert', '2025-08-19 20:12:00', 'Count from distribucionhora', 122, NULL, NULL, NULL, 0, NULL),
(251, 'insert', '2025-08-19 20:12:00', 'Skipped INSERT (no rows in distribucionhora)', 122, NULL, NULL, NULL, 0, 0),
(252, 'insert', '2025-08-19 20:12:00', 'Trigger END', 122, NULL, NULL, NULL, NULL, NULL),
(253, 'insert', '2025-08-19 20:19:54', 'Trigger START', 123, NULL, 'Programado', NULL, NULL, NULL),
(254, 'insert', '2025-08-19 20:19:54', 'After Planificacion SELECT', 123, NULL, NULL, 18, NULL, NULL),
(255, 'insert', '2025-08-19 20:19:54', 'After detalles_planificacion INSERT', 123, 178, 'Programado', NULL, NULL, NULL),
(256, 'insert', '2025-08-19 20:19:54', 'CONDITION NOT MET for distrib_planif', 123, 178, 'Programado', NULL, NULL, 0),
(257, 'insert', '2025-08-19 20:19:54', 'Trigger END', 123, NULL, NULL, NULL, NULL, NULL),
(258, 'insert', '2025-08-21 19:15:59', 'Trigger START', 124, NULL, 'En revisión', NULL, NULL, NULL),
(259, 'insert', '2025-08-21 19:15:59', 'After Planificacion SELECT', 124, NULL, NULL, 17, NULL, NULL),
(260, 'insert', '2025-08-21 19:15:59', 'After detalles_planificacion INSERT', 124, 179, 'En revisión', NULL, NULL, NULL),
(261, 'insert', '2025-08-21 19:15:59', 'CONDITION NOT MET for distrib_planif', 124, 179, 'En revisión', NULL, NULL, 0),
(262, 'insert', '2025-08-21 19:15:59', 'Trigger END', 124, NULL, NULL, NULL, NULL, NULL),
(263, 'insert', '2025-08-21 19:31:11', 'Trigger START', 125, NULL, 'En proceso', NULL, NULL, NULL),
(264, 'insert', '2025-08-21 19:31:11', 'After Planificacion SELECT', 125, NULL, NULL, 17, NULL, NULL),
(265, 'insert', '2025-08-21 19:31:11', 'After detalles_planificacion INSERT', 125, 180, 'En proceso', NULL, NULL, NULL),
(266, 'insert', '2025-08-21 19:31:11', 'CONDITION NOT MET for distrib_planif', 125, 180, 'En proceso', NULL, NULL, 0),
(267, 'insert', '2025-08-21 19:31:11', 'Trigger END', 125, NULL, NULL, NULL, NULL, NULL),
(268, 'insert', '2025-08-21 21:52:20', 'Trigger START', 126, NULL, 'En proceso', NULL, NULL, NULL),
(269, 'insert', '2025-08-21 21:52:20', 'After Planificacion SELECT', 126, NULL, NULL, 19, NULL, NULL),
(270, 'insert', '2025-08-21 21:52:20', 'After detalles_planificacion INSERT', 126, 181, 'En proceso', NULL, NULL, NULL),
(271, 'insert', '2025-08-21 21:52:20', 'CONDITION NOT MET for distrib_planif', 126, 181, 'En proceso', NULL, NULL, 0),
(272, 'insert', '2025-08-21 21:52:20', 'Trigger END', 126, NULL, NULL, NULL, NULL, NULL),
(273, 'insert', '2025-08-22 14:00:09', 'Trigger START', 127, NULL, 'Completo', NULL, NULL, NULL),
(274, 'insert', '2025-08-22 14:00:09', 'After Planificacion SELECT', 127, NULL, NULL, 18, NULL, NULL),
(275, 'insert', '2025-08-22 14:00:09', 'After detalles_planificacion INSERT', 127, 182, 'Completo', NULL, NULL, NULL),
(276, 'insert', '2025-08-22 14:00:09', 'CONDITION MET for distrib_planif', 127, 182, 'Completo', NULL, NULL, 0),
(277, 'insert', '2025-08-22 14:00:09', 'Count from distribucionhora', 127, NULL, NULL, NULL, 0, NULL),
(278, 'insert', '2025-08-22 14:00:09', 'Skipped INSERT (no rows in distribucionhora)', 127, NULL, NULL, NULL, 0, 0),
(279, 'insert', '2025-08-22 14:00:09', 'Trigger END', 127, NULL, NULL, NULL, NULL, NULL),
(280, 'insert', '2025-08-22 14:39:00', 'Trigger START', 128, NULL, 'Programado', NULL, NULL, NULL),
(281, 'insert', '2025-08-22 14:39:00', 'After Planificacion SELECT', 128, NULL, NULL, 15, NULL, NULL),
(282, 'insert', '2025-08-22 14:39:00', 'After detalles_planificacion INSERT', 128, 183, 'Programado', NULL, NULL, NULL),
(283, 'insert', '2025-08-22 14:39:00', 'CONDITION NOT MET for distrib_planif', 128, 183, 'Programado', NULL, NULL, 0),
(284, 'insert', '2025-08-22 14:39:00', 'Trigger END', 128, NULL, NULL, NULL, NULL, NULL),
(285, 'insert', '2025-08-22 17:38:56', 'Trigger START', 129, NULL, 'En revisión', NULL, NULL, NULL),
(286, 'insert', '2025-08-22 17:38:56', 'After Planificacion SELECT', 129, NULL, NULL, 16, NULL, NULL),
(287, 'insert', '2025-08-22 17:38:56', 'After detalles_planificacion INSERT', 129, 184, 'En revisión', NULL, NULL, NULL),
(288, 'insert', '2025-08-22 17:38:56', 'CONDITION NOT MET for distrib_planif', 129, 184, 'En revisión', NULL, NULL, 0),
(289, 'insert', '2025-08-22 17:38:56', 'Trigger END', 129, NULL, NULL, NULL, NULL, NULL),
(290, 'insert', '2025-08-25 13:33:40', 'Trigger START', 130, NULL, 'En proceso', NULL, NULL, NULL),
(291, 'insert', '2025-08-25 13:33:40', 'After Planificacion SELECT', 130, NULL, NULL, 16, NULL, NULL),
(292, 'insert', '2025-08-25 13:33:40', 'After detalles_planificacion INSERT', 130, 185, 'En proceso', NULL, NULL, NULL),
(293, 'insert', '2025-08-25 13:33:40', 'CONDITION NOT MET for distrib_planif', 130, 185, 'En proceso', NULL, NULL, 0),
(294, 'insert', '2025-08-25 13:33:40', 'Trigger END', 130, NULL, NULL, NULL, NULL, NULL),
(295, 'insert', '2025-08-25 13:35:27', 'Trigger START', 131, NULL, 'Programado', NULL, NULL, NULL),
(296, 'insert', '2025-08-25 13:35:27', 'After Planificacion SELECT', 131, NULL, NULL, 16, NULL, NULL),
(297, 'insert', '2025-08-25 13:35:27', 'After detalles_planificacion INSERT', 131, 186, 'Programado', NULL, NULL, NULL),
(298, 'insert', '2025-08-25 13:35:27', 'CONDITION NOT MET for distrib_planif', 131, 186, 'Programado', NULL, NULL, 0),
(299, 'insert', '2025-08-25 13:35:27', 'Trigger END', 131, NULL, NULL, NULL, NULL, NULL),
(300, 'insert', '2025-08-25 13:36:34', 'Trigger START', 132, NULL, 'En proceso', NULL, NULL, NULL),
(301, 'insert', '2025-08-25 13:36:34', 'After Planificacion SELECT', 132, NULL, NULL, 16, NULL, NULL),
(302, 'insert', '2025-08-25 13:36:34', 'After detalles_planificacion INSERT', 132, 187, 'En proceso', NULL, NULL, NULL),
(303, 'insert', '2025-08-25 13:36:34', 'CONDITION NOT MET for distrib_planif', 132, 187, 'En proceso', NULL, NULL, 0),
(304, 'insert', '2025-08-25 13:36:34', 'Trigger END', 132, NULL, NULL, NULL, NULL, NULL),
(305, 'insert', '2025-08-25 14:05:54', 'Trigger START', 133, NULL, 'En proceso', NULL, NULL, NULL),
(306, 'insert', '2025-08-25 14:05:54', 'After Planificacion SELECT', 133, NULL, NULL, 23, NULL, NULL),
(307, 'insert', '2025-08-25 14:05:54', 'After detalles_planificacion INSERT', 133, 188, 'En proceso', NULL, NULL, NULL),
(308, 'insert', '2025-08-25 14:05:54', 'CONDITION NOT MET for distrib_planif', 133, 188, 'En proceso', NULL, NULL, 0),
(309, 'insert', '2025-08-25 14:05:54', 'Trigger END', 133, NULL, NULL, NULL, NULL, NULL),
(310, 'insert', '2025-08-25 14:07:20', 'Trigger START', 134, NULL, 'En proceso', NULL, NULL, NULL),
(311, 'insert', '2025-08-25 14:07:20', 'After Planificacion SELECT', 134, NULL, NULL, 23, NULL, NULL),
(312, 'insert', '2025-08-25 14:07:20', 'After detalles_planificacion INSERT', 134, 189, 'En proceso', NULL, NULL, NULL),
(313, 'insert', '2025-08-25 14:07:20', 'CONDITION NOT MET for distrib_planif', 134, 189, 'En proceso', NULL, NULL, 0),
(314, 'insert', '2025-08-25 14:07:20', 'Trigger END', 134, NULL, NULL, NULL, NULL, NULL),
(315, 'insert', '2025-08-25 14:16:00', 'Trigger START', 135, NULL, 'Programado', NULL, NULL, NULL),
(316, 'insert', '2025-08-25 14:16:00', 'After Planificacion SELECT', 135, NULL, NULL, 21, NULL, NULL),
(317, 'insert', '2025-08-25 14:16:00', 'After detalles_planificacion INSERT', 135, 190, 'Programado', NULL, NULL, NULL),
(318, 'insert', '2025-08-25 14:16:00', 'CONDITION NOT MET for distrib_planif', 135, 190, 'Programado', NULL, NULL, 0),
(319, 'insert', '2025-08-25 14:16:00', 'Trigger END', 135, NULL, NULL, NULL, NULL, NULL),
(320, 'insert', '2025-08-25 14:19:45', 'Trigger START', 136, NULL, 'En proceso', NULL, NULL, NULL),
(321, 'insert', '2025-08-25 14:19:45', 'After Planificacion SELECT', 136, NULL, NULL, 17, NULL, NULL),
(322, 'insert', '2025-08-25 14:19:45', 'After detalles_planificacion INSERT', 136, 191, 'En proceso', NULL, NULL, NULL),
(323, 'insert', '2025-08-25 14:19:45', 'CONDITION NOT MET for distrib_planif', 136, 191, 'En proceso', NULL, NULL, 0),
(324, 'insert', '2025-08-25 14:19:45', 'Trigger END', 136, NULL, NULL, NULL, NULL, NULL),
(325, 'insert', '2025-08-25 14:58:34', 'Trigger START', 137, NULL, 'Completo', NULL, NULL, NULL),
(326, 'insert', '2025-08-25 14:58:34', 'After Planificacion SELECT', 137, NULL, NULL, 19, NULL, NULL),
(327, 'insert', '2025-08-25 14:58:34', 'After detalles_planificacion INSERT', 137, 192, 'Completo', NULL, NULL, NULL),
(328, 'insert', '2025-08-25 14:58:34', 'CONDITION MET for distrib_planif', 137, 192, 'Completo', NULL, NULL, 0),
(329, 'insert', '2025-08-25 14:58:34', 'Count from distribucionhora', 137, NULL, NULL, NULL, 0, NULL),
(330, 'insert', '2025-08-25 14:58:34', 'Skipped INSERT (no rows in distribucionhora)', 137, NULL, NULL, NULL, 0, 0),
(331, 'insert', '2025-08-25 14:58:34', 'Trigger END', 137, NULL, NULL, NULL, NULL, NULL),
(332, 'insert', '2025-08-25 15:07:39', 'Trigger START', 138, NULL, 'En revisión', NULL, NULL, NULL),
(333, 'insert', '2025-08-25 15:07:39', 'After Planificacion SELECT', 138, NULL, NULL, 19, NULL, NULL),
(334, 'insert', '2025-08-25 15:07:39', 'After detalles_planificacion INSERT', 138, 193, 'En revisión', NULL, NULL, NULL),
(335, 'insert', '2025-08-25 15:07:39', 'CONDITION NOT MET for distrib_planif', 138, 193, 'En revisión', NULL, NULL, 0),
(336, 'insert', '2025-08-25 15:07:39', 'Trigger END', 138, NULL, NULL, NULL, NULL, NULL),
(337, 'insert', '2025-08-29 00:52:04', 'Trigger START', 139, NULL, 'En revisión', NULL, NULL, NULL),
(338, 'insert', '2025-08-29 00:52:04', 'After Planificacion SELECT', 139, NULL, NULL, 17, NULL, NULL),
(339, 'insert', '2025-08-29 00:52:04', 'After detalles_planificacion INSERT', 139, 194, 'En revisión', NULL, NULL, NULL),
(340, 'insert', '2025-08-29 00:52:04', 'CONDITION NOT MET for distrib_planif', 139, 194, 'En revisión', NULL, NULL, 0),
(341, 'insert', '2025-08-29 00:52:04', 'Trigger END', 139, NULL, NULL, NULL, NULL, NULL),
(342, 'insert', '2025-08-29 01:07:40', 'Trigger START', 140, NULL, 'Completo', NULL, NULL, NULL),
(343, 'insert', '2025-08-29 01:07:40', 'After Planificacion SELECT', 140, NULL, NULL, 15, NULL, NULL),
(344, 'insert', '2025-08-29 01:07:40', 'After detalles_planificacion INSERT', 140, 195, 'Completo', NULL, NULL, NULL),
(345, 'insert', '2025-08-29 01:07:40', 'CONDITION MET for distrib_planif', 140, 195, 'Completo', NULL, NULL, 0),
(346, 'insert', '2025-08-29 01:07:40', 'Count from distribucionhora', 140, NULL, NULL, NULL, 0, NULL),
(347, 'insert', '2025-08-29 01:07:40', 'Skipped INSERT (no rows in distribucionhora)', 140, NULL, NULL, NULL, 0, 0),
(348, 'insert', '2025-08-29 01:07:40', 'Trigger END', 140, NULL, NULL, NULL, NULL, NULL),
(349, 'insert', '2025-08-29 14:44:48', 'Trigger START', 141, NULL, 'Completo', NULL, NULL, NULL),
(350, 'insert', '2025-08-29 14:44:48', 'After Planificacion SELECT', 141, NULL, NULL, 18, NULL, NULL),
(351, 'insert', '2025-08-29 14:44:48', 'After detalles_planificacion INSERT', 141, 196, 'Completo', NULL, NULL, NULL),
(352, 'insert', '2025-08-29 14:44:48', 'CONDITION MET for distrib_planif', 141, 196, 'Completo', NULL, NULL, 0),
(353, 'insert', '2025-08-29 14:44:48', 'Count from distribucionhora', 141, NULL, NULL, NULL, 0, NULL),
(354, 'insert', '2025-08-29 14:44:48', 'Skipped INSERT (no rows in distribucionhora)', 141, NULL, NULL, NULL, 0, 0),
(355, 'insert', '2025-08-29 14:44:48', 'Trigger END', 141, NULL, NULL, NULL, NULL, NULL),
(356, 'insert', '2025-08-29 16:54:50', 'Trigger START', 142, NULL, 'Completo', NULL, NULL, NULL),
(357, 'insert', '2025-08-29 16:54:50', 'After Planificacion SELECT', 142, NULL, NULL, 23, NULL, NULL),
(358, 'insert', '2025-08-29 16:54:50', 'After detalles_planificacion INSERT', 142, 197, 'Completo', NULL, NULL, NULL),
(359, 'insert', '2025-08-29 16:54:50', 'CONDITION MET for distrib_planif', 142, 197, 'Completo', NULL, NULL, 0),
(360, 'insert', '2025-08-29 16:54:50', 'Count from distribucionhora', 142, NULL, NULL, NULL, 0, NULL),
(361, 'insert', '2025-08-29 16:54:50', 'Skipped INSERT (no rows in distribucionhora)', 142, NULL, NULL, NULL, 0, 0),
(362, 'insert', '2025-08-29 16:54:50', 'Trigger END', 142, NULL, NULL, NULL, NULL, NULL),
(363, 'insert', '2025-08-29 18:02:06', 'Trigger START', 143, NULL, 'Completo', NULL, NULL, NULL),
(364, 'insert', '2025-08-29 18:02:06', 'After Planificacion SELECT', 143, NULL, NULL, 16, NULL, NULL),
(365, 'insert', '2025-08-29 18:02:06', 'After detalles_planificacion INSERT', 143, 198, 'Completo', NULL, NULL, NULL),
(366, 'insert', '2025-08-29 18:02:06', 'CONDITION MET for distrib_planif', 143, 198, 'Completo', NULL, NULL, 0),
(367, 'insert', '2025-08-29 18:02:06', 'Count from distribucionhora', 143, NULL, NULL, NULL, 0, NULL),
(368, 'insert', '2025-08-29 18:02:06', 'Skipped INSERT (no rows in distribucionhora)', 143, NULL, NULL, NULL, 0, 0),
(369, 'insert', '2025-08-29 18:02:06', 'Trigger END', 143, NULL, NULL, NULL, NULL, NULL),
(370, 'insert', '2025-08-29 21:24:40', 'Trigger START', 144, NULL, 'Completo', NULL, NULL, NULL),
(371, 'insert', '2025-08-29 21:24:40', 'After Planificacion SELECT', 144, NULL, NULL, 15, NULL, NULL),
(372, 'insert', '2025-08-29 21:24:40', 'After detalles_planificacion INSERT', 144, 199, 'Completo', NULL, NULL, NULL),
(373, 'insert', '2025-08-29 21:24:40', 'CONDITION MET for distrib_planif', 144, 199, 'Completo', NULL, NULL, 0),
(374, 'insert', '2025-08-29 21:24:40', 'Count from distribucionhora', 144, NULL, NULL, NULL, 0, NULL),
(375, 'insert', '2025-08-29 21:24:40', 'Skipped INSERT (no rows in distribucionhora)', 144, NULL, NULL, NULL, 0, 0),
(376, 'insert', '2025-08-29 21:24:40', 'Trigger END', 144, NULL, NULL, NULL, NULL, NULL),
(377, 'insert', '2025-08-31 23:48:02', 'Trigger START', 145, NULL, 'En proceso', NULL, NULL, NULL),
(378, 'insert', '2025-08-31 23:48:02', 'After Planificacion SELECT', 145, NULL, NULL, NULL, NULL, NULL),
(379, 'insert', '2025-08-31 23:48:02', 'v_idplanificacion IS NULL', 145, NULL, NULL, NULL, NULL, 0),
(380, 'insert', '2025-08-31 23:48:02', 'Trigger END', 145, NULL, NULL, NULL, NULL, NULL),
(381, 'insert', '2025-09-01 00:04:56', 'Trigger START', 146, NULL, 'Programado', NULL, NULL, NULL),
(382, 'insert', '2025-09-01 00:04:56', 'After Planificacion SELECT', 146, NULL, NULL, NULL, NULL, NULL),
(383, 'insert', '2025-09-01 00:04:56', 'v_idplanificacion IS NULL', 146, NULL, NULL, NULL, NULL, 0),
(384, 'insert', '2025-09-01 00:04:56', 'Trigger END', 146, NULL, NULL, NULL, NULL, NULL),
(385, 'insert', '2025-09-01 00:09:35', 'Trigger START', 147, NULL, 'Programado', NULL, NULL, NULL),
(386, 'insert', '2025-09-01 00:09:35', 'After Planificacion SELECT', 147, NULL, NULL, NULL, NULL, NULL),
(387, 'insert', '2025-09-01 00:09:35', 'v_idplanificacion IS NULL', 147, NULL, NULL, NULL, NULL, 0),
(388, 'insert', '2025-09-01 00:09:35', 'Trigger END', 147, NULL, NULL, NULL, NULL, NULL),
(389, 'insert', '2025-09-01 13:28:05', 'Trigger START', 148, NULL, 'En proceso', NULL, NULL, NULL),
(390, 'insert', '2025-09-01 13:28:05', 'After Planificacion SELECT', 148, NULL, NULL, NULL, NULL, NULL),
(391, 'insert', '2025-09-01 13:28:05', 'v_idplanificacion IS NULL', 148, NULL, NULL, NULL, NULL, 0),
(392, 'insert', '2025-09-01 13:28:05', 'Trigger END', 148, NULL, NULL, NULL, NULL, NULL),
(393, 'insert', '2025-09-01 13:32:11', 'Trigger START', 149, NULL, 'En proceso', NULL, NULL, NULL),
(394, 'insert', '2025-09-01 13:32:11', 'After Planificacion SELECT', 149, NULL, NULL, NULL, NULL, NULL),
(395, 'insert', '2025-09-01 13:32:11', 'v_idplanificacion IS NULL', 149, NULL, NULL, NULL, NULL, 0),
(396, 'insert', '2025-09-01 13:32:11', 'Trigger END', 149, NULL, NULL, NULL, NULL, NULL),
(397, 'insert', '2025-09-01 13:36:26', 'Trigger START', 150, NULL, 'Programado', NULL, NULL, NULL),
(398, 'insert', '2025-09-01 13:36:26', 'After Planificacion SELECT', 150, NULL, NULL, NULL, NULL, NULL),
(399, 'insert', '2025-09-01 13:36:26', 'v_idplanificacion IS NULL', 150, NULL, NULL, NULL, NULL, 0),
(400, 'insert', '2025-09-01 13:36:26', 'Trigger END', 150, NULL, NULL, NULL, NULL, NULL),
(401, 'insert', '2025-09-01 13:37:42', 'Trigger START', 151, NULL, 'En proceso', NULL, NULL, NULL),
(402, 'insert', '2025-09-01 13:37:42', 'After Planificacion SELECT', 151, NULL, NULL, NULL, NULL, NULL),
(403, 'insert', '2025-09-01 13:37:42', 'v_idplanificacion IS NULL', 151, NULL, NULL, NULL, NULL, 0),
(404, 'insert', '2025-09-01 13:37:42', 'Trigger END', 151, NULL, NULL, NULL, NULL, NULL),
(405, 'insert', '2025-09-01 13:46:33', 'Trigger START', 152, NULL, 'En proceso', NULL, NULL, NULL),
(406, 'insert', '2025-09-01 13:46:33', 'After Planificacion SELECT', 152, NULL, NULL, NULL, NULL, NULL),
(407, 'insert', '2025-09-01 13:46:33', 'v_idplanificacion IS NULL', 152, NULL, NULL, NULL, NULL, 0),
(408, 'insert', '2025-09-01 13:46:33', 'Trigger END', 152, NULL, NULL, NULL, NULL, NULL),
(409, 'insert', '2025-09-01 16:51:13', 'Trigger START', 153, NULL, 'Programado', NULL, NULL, NULL),
(410, 'insert', '2025-09-01 16:51:13', 'After Planificacion SELECT', 153, NULL, NULL, NULL, NULL, NULL),
(411, 'insert', '2025-09-01 16:51:13', 'v_idplanificacion IS NULL', 153, NULL, NULL, NULL, NULL, 0),
(412, 'insert', '2025-09-01 16:51:13', 'Trigger END', 153, NULL, NULL, NULL, NULL, NULL),
(413, 'insert', '2025-09-01 16:53:53', 'Trigger START', 154, NULL, 'Programado', NULL, NULL, NULL),
(414, 'insert', '2025-09-01 16:53:53', 'After Planificacion SELECT', 154, NULL, NULL, NULL, NULL, NULL),
(415, 'insert', '2025-09-01 16:53:53', 'v_idplanificacion IS NULL', 154, NULL, NULL, NULL, NULL, 0),
(416, 'insert', '2025-09-01 16:53:53', 'Trigger END', 154, NULL, NULL, NULL, NULL, NULL),
(417, 'insert', '2025-09-02 16:48:04', 'Trigger START', 155, NULL, 'En proceso', NULL, NULL, NULL),
(418, 'insert', '2025-09-02 16:48:04', 'After Planificacion SELECT', 155, NULL, NULL, NULL, NULL, NULL),
(419, 'insert', '2025-09-02 16:48:04', 'v_idplanificacion IS NULL', 155, NULL, NULL, NULL, NULL, 0),
(420, 'insert', '2025-09-02 16:48:04', 'Trigger END', 155, NULL, NULL, NULL, NULL, NULL),
(421, 'insert', '2025-09-02 20:56:20', 'Trigger START', 156, NULL, 'En revisión', NULL, NULL, NULL),
(422, 'insert', '2025-09-02 20:56:20', 'After Planificacion SELECT', 156, NULL, NULL, NULL, NULL, NULL),
(423, 'insert', '2025-09-02 20:56:20', 'v_idplanificacion IS NULL', 156, NULL, NULL, NULL, NULL, 0),
(424, 'insert', '2025-09-02 20:56:20', 'Trigger END', 156, NULL, NULL, NULL, NULL, NULL),
(425, 'insert', '2025-09-02 21:31:22', 'Trigger START', 157, NULL, 'Completo', NULL, NULL, NULL),
(426, 'insert', '2025-09-02 21:31:22', 'After Planificacion SELECT', 157, NULL, NULL, NULL, NULL, NULL),
(427, 'insert', '2025-09-02 21:31:22', 'v_idplanificacion IS NULL', 157, NULL, NULL, NULL, NULL, 0),
(428, 'insert', '2025-09-02 21:31:22', 'Trigger END', 157, NULL, NULL, NULL, NULL, NULL),
(429, 'insert', '2025-09-03 14:13:14', 'Trigger START', 158, NULL, 'En proceso', NULL, NULL, NULL),
(430, 'insert', '2025-09-03 14:13:14', 'After Planificacion SELECT', 158, NULL, NULL, NULL, NULL, NULL),
(431, 'insert', '2025-09-03 14:13:14', 'v_idplanificacion IS NULL', 158, NULL, NULL, NULL, NULL, 0),
(432, 'insert', '2025-09-03 14:13:14', 'Trigger END', 158, NULL, NULL, NULL, NULL, NULL),
(433, 'insert', '2025-09-03 15:41:38', 'Trigger START', 159, NULL, 'Programado', NULL, NULL, NULL),
(434, 'insert', '2025-09-03 15:41:38', 'After Planificacion SELECT', 159, NULL, NULL, NULL, NULL, NULL),
(435, 'insert', '2025-09-03 15:41:38', 'v_idplanificacion IS NULL', 159, NULL, NULL, NULL, NULL, 0),
(436, 'insert', '2025-09-03 15:41:38', 'Trigger END', 159, NULL, NULL, NULL, NULL, NULL),
(437, 'insert', '2025-09-05 21:14:32', 'Trigger START', 160, NULL, 'Completo', NULL, NULL, NULL),
(438, 'insert', '2025-09-05 21:14:32', 'After Planificacion SELECT', 160, NULL, NULL, NULL, NULL, NULL),
(439, 'insert', '2025-09-05 21:14:32', 'v_idplanificacion IS NULL', 160, NULL, NULL, NULL, NULL, 0),
(440, 'insert', '2025-09-05 21:14:32', 'Trigger END', 160, NULL, NULL, NULL, NULL, NULL),
(441, 'insert', '2025-09-05 21:15:43', 'Trigger START', 161, NULL, 'Completo', NULL, NULL, NULL),
(442, 'insert', '2025-09-05 21:15:43', 'After Planificacion SELECT', 161, NULL, NULL, NULL, NULL, NULL),
(443, 'insert', '2025-09-05 21:15:43', 'v_idplanificacion IS NULL', 161, NULL, NULL, NULL, NULL, 0),
(444, 'insert', '2025-09-05 21:15:43', 'Trigger END', 161, NULL, NULL, NULL, NULL, NULL),
(445, 'insert', '2025-09-05 21:51:45', 'Trigger START', 162, NULL, 'Completo', NULL, NULL, NULL),
(446, 'insert', '2025-09-05 21:51:45', 'After Planificacion SELECT', 162, NULL, NULL, NULL, NULL, NULL),
(447, 'insert', '2025-09-05 21:51:45', 'v_idplanificacion IS NULL', 162, NULL, NULL, NULL, NULL, 0),
(448, 'insert', '2025-09-05 21:51:45', 'Trigger END', 162, NULL, NULL, NULL, NULL, NULL),
(449, 'insert', '2025-09-08 14:09:52', 'Trigger START', 163, NULL, 'En proceso', NULL, NULL, NULL),
(450, 'insert', '2025-09-08 14:09:52', 'After Planificacion SELECT', 163, NULL, NULL, NULL, NULL, NULL),
(451, 'insert', '2025-09-08 14:09:52', 'v_idplanificacion IS NULL', 163, NULL, NULL, NULL, NULL, 0),
(452, 'insert', '2025-09-08 14:09:52', 'Trigger END', 163, NULL, NULL, NULL, NULL, NULL),
(453, 'insert', '2025-09-08 17:52:24', 'Trigger START', 164, NULL, 'En proceso', NULL, NULL, NULL),
(454, 'insert', '2025-09-08 17:52:24', 'After Planificacion SELECT', 164, NULL, NULL, NULL, NULL, NULL),
(455, 'insert', '2025-09-08 17:52:24', 'v_idplanificacion IS NULL', 164, NULL, NULL, NULL, NULL, 0),
(456, 'insert', '2025-09-08 17:52:24', 'Trigger END', 164, NULL, NULL, NULL, NULL, NULL),
(457, 'insert', '2025-09-08 17:53:27', 'Trigger START', 165, NULL, 'En proceso', NULL, NULL, NULL),
(458, 'insert', '2025-09-08 17:53:27', 'After Planificacion SELECT', 165, NULL, NULL, NULL, NULL, NULL),
(459, 'insert', '2025-09-08 17:53:27', 'v_idplanificacion IS NULL', 165, NULL, NULL, NULL, NULL, 0),
(460, 'insert', '2025-09-08 17:53:27', 'Trigger END', 165, NULL, NULL, NULL, NULL, NULL),
(461, 'insert', '2025-09-08 22:18:01', 'Trigger START', 166, NULL, 'En proceso', NULL, NULL, NULL),
(462, 'insert', '2025-09-08 22:18:01', 'After Planificacion SELECT', 166, NULL, NULL, NULL, NULL, NULL),
(463, 'insert', '2025-09-08 22:18:01', 'v_idplanificacion IS NULL', 166, NULL, NULL, NULL, NULL, 0),
(464, 'insert', '2025-09-08 22:18:01', 'Trigger END', 166, NULL, NULL, NULL, NULL, NULL),
(465, 'insert', '2025-09-08 22:26:35', 'Trigger START', 167, NULL, 'Completo', NULL, NULL, NULL),
(466, 'insert', '2025-09-08 22:26:35', 'After Planificacion SELECT', 167, NULL, NULL, NULL, NULL, NULL),
(467, 'insert', '2025-09-08 22:26:35', 'v_idplanificacion IS NULL', 167, NULL, NULL, NULL, NULL, 0),
(468, 'insert', '2025-09-08 22:26:35', 'Trigger END', 167, NULL, NULL, NULL, NULL, NULL),
(469, 'insert', '2025-09-09 23:47:59', 'Trigger START', 168, NULL, 'Programado', NULL, NULL, NULL),
(470, 'insert', '2025-09-09 23:47:59', 'After Planificacion SELECT', 168, NULL, NULL, NULL, NULL, NULL),
(471, 'insert', '2025-09-09 23:47:59', 'v_idplanificacion IS NULL', 168, NULL, NULL, NULL, NULL, 0),
(472, 'insert', '2025-09-09 23:47:59', 'Trigger END', 168, NULL, NULL, NULL, NULL, NULL),
(473, 'insert', '2025-09-11 20:27:22', 'Trigger START', 169, NULL, 'Completo', NULL, NULL, NULL),
(474, 'insert', '2025-09-11 20:27:22', 'After Planificacion SELECT', 169, NULL, NULL, NULL, NULL, NULL),
(475, 'insert', '2025-09-11 20:27:22', 'v_idplanificacion IS NULL', 169, NULL, NULL, NULL, NULL, 0),
(476, 'insert', '2025-09-11 20:27:22', 'Trigger END', 169, NULL, NULL, NULL, NULL, NULL),
(477, 'insert', '2025-09-11 20:46:33', 'Trigger START', 170, NULL, 'Completo', NULL, NULL, NULL),
(478, 'insert', '2025-09-11 20:46:33', 'After Planificacion SELECT', 170, NULL, NULL, NULL, NULL, NULL),
(479, 'insert', '2025-09-11 20:46:33', 'v_idplanificacion IS NULL', 170, NULL, NULL, NULL, NULL, 0),
(480, 'insert', '2025-09-11 20:46:33', 'Trigger END', 170, NULL, NULL, NULL, NULL, NULL),
(481, 'insert', '2025-09-12 16:57:02', 'Trigger START', 171, NULL, 'Programado', NULL, NULL, NULL),
(482, 'insert', '2025-09-12 16:57:02', 'After Planificacion SELECT', 171, NULL, NULL, NULL, NULL, NULL),
(483, 'insert', '2025-09-12 16:57:02', 'v_idplanificacion IS NULL', 171, NULL, NULL, NULL, NULL, 0),
(484, 'insert', '2025-09-12 16:57:02', 'Trigger END', 171, NULL, NULL, NULL, NULL, NULL),
(485, 'insert', '2025-09-12 19:45:59', 'Trigger START', 172, NULL, 'Programado', NULL, NULL, NULL),
(486, 'insert', '2025-09-12 19:45:59', 'After Planificacion SELECT', 172, NULL, NULL, NULL, NULL, NULL),
(487, 'insert', '2025-09-12 19:45:59', 'v_idplanificacion IS NULL', 172, NULL, NULL, NULL, NULL, 0),
(488, 'insert', '2025-09-12 19:45:59', 'Trigger END', 172, NULL, NULL, NULL, NULL, NULL),
(489, 'insert', '2025-09-16 01:27:19', 'Trigger START', 173, NULL, 'Completo', NULL, NULL, NULL),
(490, 'insert', '2025-09-16 01:27:19', 'After Planificacion SELECT', 173, NULL, NULL, NULL, NULL, NULL),
(491, 'insert', '2025-09-16 01:27:19', 'v_idplanificacion IS NULL', 173, NULL, NULL, NULL, NULL, 0),
(492, 'insert', '2025-09-16 01:27:19', 'Trigger END', 173, NULL, NULL, NULL, NULL, NULL);
INSERT INTO `trigger_debug_log` (`log_id`, `trigger_name`, `log_timestamp`, `message`, `idliquidacion_val`, `iddetalle_val`, `estado_val`, `planificacion_id_val`, `distribucionhora_count`, `insert_attempted`) VALUES
(493, 'insert', '2025-09-17 01:30:42', 'Trigger START', 174, NULL, 'Completo', NULL, NULL, NULL),
(494, 'insert', '2025-09-17 01:30:42', 'After Planificacion SELECT', 174, NULL, NULL, NULL, NULL, NULL),
(495, 'insert', '2025-09-17 01:30:42', 'v_idplanificacion IS NULL', 174, NULL, NULL, NULL, NULL, 0),
(496, 'insert', '2025-09-17 01:30:42', 'Trigger END', 174, NULL, NULL, NULL, NULL, NULL),
(497, 'insert', '2025-09-19 21:35:18', 'Trigger START', 175, NULL, 'Completo', NULL, NULL, NULL),
(498, 'insert', '2025-09-19 21:35:18', 'After Planificacion SELECT', 175, NULL, NULL, NULL, NULL, NULL),
(499, 'insert', '2025-09-19 21:35:18', 'v_idplanificacion IS NULL', 175, NULL, NULL, NULL, NULL, 0),
(500, 'insert', '2025-09-19 21:35:18', 'Trigger END', 175, NULL, NULL, NULL, NULL, NULL),
(501, 'insert', '2025-09-19 21:38:39', 'Trigger START', 176, NULL, 'En proceso', NULL, NULL, NULL),
(502, 'insert', '2025-09-19 21:38:39', 'After Planificacion SELECT', 176, NULL, NULL, NULL, NULL, NULL),
(503, 'insert', '2025-09-19 21:38:39', 'v_idplanificacion IS NULL', 176, NULL, NULL, NULL, NULL, 0),
(504, 'insert', '2025-09-19 21:38:39', 'Trigger END', 176, NULL, NULL, NULL, NULL, NULL),
(505, 'insert', '2025-09-19 21:38:51', 'Trigger START', 177, NULL, 'Completo', NULL, NULL, NULL),
(506, 'insert', '2025-09-19 21:38:51', 'After Planificacion SELECT', 177, NULL, NULL, NULL, NULL, NULL),
(507, 'insert', '2025-09-19 21:38:51', 'v_idplanificacion IS NULL', 177, NULL, NULL, NULL, NULL, 0),
(508, 'insert', '2025-09-19 21:38:51', 'Trigger END', 177, NULL, NULL, NULL, NULL, NULL),
(509, 'insert', '2025-09-19 21:42:18', 'Trigger START', 178, NULL, 'En proceso', NULL, NULL, NULL),
(510, 'insert', '2025-09-19 21:42:18', 'After Planificacion SELECT', 178, NULL, NULL, NULL, NULL, NULL),
(511, 'insert', '2025-09-19 21:42:18', 'v_idplanificacion IS NULL', 178, NULL, NULL, NULL, NULL, 0),
(512, 'insert', '2025-09-19 21:42:18', 'Trigger END', 178, NULL, NULL, NULL, NULL, NULL),
(513, 'insert', '2025-09-22 13:34:03', 'Trigger START', 179, NULL, 'Completo', NULL, NULL, NULL),
(514, 'insert', '2025-09-22 13:34:03', 'After Planificacion SELECT', 179, NULL, NULL, NULL, NULL, NULL),
(515, 'insert', '2025-09-22 13:34:03', 'v_idplanificacion IS NULL', 179, NULL, NULL, NULL, NULL, 0),
(516, 'insert', '2025-09-22 13:34:03', 'Trigger END', 179, NULL, NULL, NULL, NULL, NULL),
(517, 'insert', '2025-09-22 13:37:45', 'Trigger START', 180, NULL, 'En proceso', NULL, NULL, NULL),
(518, 'insert', '2025-09-22 13:37:45', 'After Planificacion SELECT', 180, NULL, NULL, NULL, NULL, NULL),
(519, 'insert', '2025-09-22 13:37:45', 'v_idplanificacion IS NULL', 180, NULL, NULL, NULL, NULL, 0),
(520, 'insert', '2025-09-22 13:37:45', 'Trigger END', 180, NULL, NULL, NULL, NULL, NULL),
(521, 'insert', '2025-09-22 13:42:38', 'Trigger START', 181, NULL, 'En proceso', NULL, NULL, NULL),
(522, 'insert', '2025-09-22 13:42:38', 'After Planificacion SELECT', 181, NULL, NULL, NULL, NULL, NULL),
(523, 'insert', '2025-09-22 13:42:38', 'v_idplanificacion IS NULL', 181, NULL, NULL, NULL, NULL, 0),
(524, 'insert', '2025-09-22 13:42:38', 'Trigger END', 181, NULL, NULL, NULL, NULL, NULL),
(525, 'insert', '2025-09-22 13:43:15', 'Trigger START', 182, NULL, 'En proceso', NULL, NULL, NULL),
(526, 'insert', '2025-09-22 13:43:15', 'After Planificacion SELECT', 182, NULL, NULL, NULL, NULL, NULL),
(527, 'insert', '2025-09-22 13:43:15', 'v_idplanificacion IS NULL', 182, NULL, NULL, NULL, NULL, 0),
(528, 'insert', '2025-09-22 13:43:15', 'Trigger END', 182, NULL, NULL, NULL, NULL, NULL),
(529, 'insert', '2025-09-22 13:43:46', 'Trigger START', 183, NULL, 'En proceso', NULL, NULL, NULL),
(530, 'insert', '2025-09-22 13:43:46', 'After Planificacion SELECT', 183, NULL, NULL, NULL, NULL, NULL),
(531, 'insert', '2025-09-22 13:43:46', 'v_idplanificacion IS NULL', 183, NULL, NULL, NULL, NULL, 0),
(532, 'insert', '2025-09-22 13:43:46', 'Trigger END', 183, NULL, NULL, NULL, NULL, NULL),
(533, 'insert', '2025-09-22 13:44:25', 'Trigger START', 184, NULL, 'En proceso', NULL, NULL, NULL),
(534, 'insert', '2025-09-22 13:44:25', 'After Planificacion SELECT', 184, NULL, NULL, NULL, NULL, NULL),
(535, 'insert', '2025-09-22 13:44:25', 'v_idplanificacion IS NULL', 184, NULL, NULL, NULL, NULL, 0),
(536, 'insert', '2025-09-22 13:44:25', 'Trigger END', 184, NULL, NULL, NULL, NULL, NULL),
(537, 'insert', '2025-09-22 13:45:52', 'Trigger START', 185, NULL, 'Programado', NULL, NULL, NULL),
(538, 'insert', '2025-09-22 13:45:52', 'After Planificacion SELECT', 185, NULL, NULL, NULL, NULL, NULL),
(539, 'insert', '2025-09-22 13:45:52', 'v_idplanificacion IS NULL', 185, NULL, NULL, NULL, NULL, 0),
(540, 'insert', '2025-09-22 13:45:52', 'Trigger END', 185, NULL, NULL, NULL, NULL, NULL),
(541, 'insert', '2025-09-22 13:49:06', 'Trigger START', 186, NULL, 'Programado', NULL, NULL, NULL),
(542, 'insert', '2025-09-22 13:49:06', 'After Planificacion SELECT', 186, NULL, NULL, NULL, NULL, NULL),
(543, 'insert', '2025-09-22 13:49:06', 'v_idplanificacion IS NULL', 186, NULL, NULL, NULL, NULL, 0),
(544, 'insert', '2025-09-22 13:49:06', 'Trigger END', 186, NULL, NULL, NULL, NULL, NULL),
(545, 'insert', '2025-09-22 14:59:28', 'Trigger START', 187, NULL, 'En proceso', NULL, NULL, NULL),
(546, 'insert', '2025-09-22 14:59:28', 'After Planificacion SELECT', 187, NULL, NULL, NULL, NULL, NULL),
(547, 'insert', '2025-09-22 14:59:28', 'v_idplanificacion IS NULL', 187, NULL, NULL, NULL, NULL, 0),
(548, 'insert', '2025-09-22 14:59:28', 'Trigger END', 187, NULL, NULL, NULL, NULL, NULL),
(549, 'insert', '2025-09-23 17:18:11', 'Trigger START', 188, NULL, 'En proceso', NULL, NULL, NULL),
(550, 'insert', '2025-09-23 17:18:11', 'After Planificacion SELECT', 188, NULL, NULL, NULL, NULL, NULL),
(551, 'insert', '2025-09-23 17:18:11', 'v_idplanificacion IS NULL', 188, NULL, NULL, NULL, NULL, 0),
(552, 'insert', '2025-09-23 17:18:11', 'Trigger END', 188, NULL, NULL, NULL, NULL, NULL),
(553, 'insert', '2025-09-23 19:04:23', 'Trigger START', 189, NULL, 'Completo', NULL, NULL, NULL),
(554, 'insert', '2025-09-23 19:04:23', 'After Planificacion SELECT', 189, NULL, NULL, NULL, NULL, NULL),
(555, 'insert', '2025-09-23 19:04:23', 'v_idplanificacion IS NULL', 189, NULL, NULL, NULL, NULL, 0),
(556, 'insert', '2025-09-23 19:04:23', 'Trigger END', 189, NULL, NULL, NULL, NULL, NULL),
(557, 'insert', '2025-09-23 21:51:23', 'Trigger START', 190, NULL, 'Completo', NULL, NULL, NULL),
(558, 'insert', '2025-09-23 21:51:23', 'After Planificacion SELECT', 190, NULL, NULL, NULL, NULL, NULL),
(559, 'insert', '2025-09-23 21:51:23', 'v_idplanificacion IS NULL', 190, NULL, NULL, NULL, NULL, 0),
(560, 'insert', '2025-09-23 21:51:23', 'Trigger END', 190, NULL, NULL, NULL, NULL, NULL),
(561, 'insert', '2025-09-24 15:35:10', 'Trigger START', 191, NULL, 'En proceso', NULL, NULL, NULL),
(562, 'insert', '2025-09-24 15:35:10', 'After Planificacion SELECT', 191, NULL, NULL, NULL, NULL, NULL),
(563, 'insert', '2025-09-24 15:35:10', 'v_idplanificacion IS NULL', 191, NULL, NULL, NULL, NULL, 0),
(564, 'insert', '2025-09-24 15:35:10', 'Trigger END', 191, NULL, NULL, NULL, NULL, NULL),
(565, 'insert', '2025-09-26 23:18:46', 'Trigger START', 192, NULL, 'Completo', NULL, NULL, NULL),
(566, 'insert', '2025-09-26 23:18:46', 'After Planificacion SELECT', 192, NULL, NULL, 31, NULL, NULL),
(567, 'insert', '2025-09-26 23:18:46', 'After detalles_planificacion INSERT', 192, 264, 'Completo', NULL, NULL, NULL),
(568, 'insert', '2025-09-26 23:18:46', 'CONDITION MET for distrib_planif', 192, 264, 'Completo', NULL, NULL, 0),
(569, 'insert', '2025-09-26 23:18:46', 'Count from distribucionhora', 192, NULL, NULL, NULL, 0, NULL),
(570, 'insert', '2025-09-26 23:18:46', 'Skipped INSERT (no rows in distribucionhora)', 192, NULL, NULL, NULL, 0, 0),
(571, 'insert', '2025-09-26 23:18:46', 'Trigger END', 192, NULL, NULL, NULL, NULL, NULL),
(572, 'insert', '2025-09-26 23:22:23', 'Trigger START', 193, NULL, 'En proceso', NULL, NULL, NULL),
(573, 'insert', '2025-09-26 23:22:23', 'After Planificacion SELECT', 193, NULL, NULL, 29, NULL, NULL),
(574, 'insert', '2025-09-26 23:22:23', 'After detalles_planificacion INSERT', 193, 265, 'En proceso', NULL, NULL, NULL),
(575, 'insert', '2025-09-26 23:22:23', 'CONDITION NOT MET for distrib_planif', 193, 265, 'En proceso', NULL, NULL, 0),
(576, 'insert', '2025-09-26 23:22:23', 'Trigger END', 193, NULL, NULL, NULL, NULL, NULL),
(577, 'insert', '2025-09-29 13:36:37', 'Trigger START', 194, NULL, 'En proceso', NULL, NULL, NULL),
(578, 'insert', '2025-09-29 13:36:37', 'After Planificacion SELECT', 194, NULL, NULL, 26, NULL, NULL),
(579, 'insert', '2025-09-29 13:36:37', 'After detalles_planificacion INSERT', 194, 266, 'En proceso', NULL, NULL, NULL),
(580, 'insert', '2025-09-29 13:36:37', 'CONDITION NOT MET for distrib_planif', 194, 266, 'En proceso', NULL, NULL, 0),
(581, 'insert', '2025-09-29 13:36:37', 'Trigger END', 194, NULL, NULL, NULL, NULL, NULL),
(582, 'insert', '2025-09-29 18:59:22', 'Trigger START', 195, NULL, 'Completo', NULL, NULL, NULL),
(583, 'insert', '2025-09-29 18:59:22', 'After Planificacion SELECT', 195, NULL, NULL, 31, NULL, NULL),
(584, 'insert', '2025-09-29 18:59:22', 'After detalles_planificacion INSERT', 195, 267, 'Completo', NULL, NULL, NULL),
(585, 'insert', '2025-09-29 18:59:22', 'CONDITION MET for distrib_planif', 195, 267, 'Completo', NULL, NULL, 0),
(586, 'insert', '2025-09-29 18:59:22', 'Count from distribucionhora', 195, NULL, NULL, NULL, 0, NULL),
(587, 'insert', '2025-09-29 18:59:22', 'Skipped INSERT (no rows in distribucionhora)', 195, NULL, NULL, NULL, 0, 0),
(588, 'insert', '2025-09-29 18:59:22', 'Trigger END', 195, NULL, NULL, NULL, NULL, NULL),
(589, 'insert', '2025-09-30 19:27:23', 'Trigger START', 196, NULL, 'Completo', NULL, NULL, NULL),
(590, 'insert', '2025-09-30 19:27:23', 'After Planificacion SELECT', 196, NULL, NULL, 26, NULL, NULL),
(591, 'insert', '2025-09-30 19:27:23', 'After detalles_planificacion INSERT', 196, 268, 'Completo', NULL, NULL, NULL),
(592, 'insert', '2025-09-30 19:27:23', 'CONDITION MET for distrib_planif', 196, 268, 'Completo', NULL, NULL, 0),
(593, 'insert', '2025-09-30 19:27:23', 'Count from distribucionhora', 196, NULL, NULL, NULL, 0, NULL),
(594, 'insert', '2025-09-30 19:27:23', 'Skipped INSERT (no rows in distribucionhora)', 196, NULL, NULL, NULL, 0, 0),
(595, 'insert', '2025-09-30 19:27:23', 'Trigger END', 196, NULL, NULL, NULL, NULL, NULL),
(596, 'insert', '2025-09-30 19:42:21', 'Trigger START', 197, NULL, 'Completo', NULL, NULL, NULL),
(597, 'insert', '2025-09-30 19:42:21', 'After Planificacion SELECT', 197, NULL, NULL, 24, NULL, NULL),
(598, 'insert', '2025-09-30 19:42:21', 'After detalles_planificacion INSERT', 197, 269, 'Completo', NULL, NULL, NULL),
(599, 'insert', '2025-09-30 19:42:21', 'CONDITION MET for distrib_planif', 197, 269, 'Completo', NULL, NULL, 0),
(600, 'insert', '2025-09-30 19:42:21', 'Count from distribucionhora', 197, NULL, NULL, NULL, 0, NULL),
(601, 'insert', '2025-09-30 19:42:21', 'Skipped INSERT (no rows in distribucionhora)', 197, NULL, NULL, NULL, 0, 0),
(602, 'insert', '2025-09-30 19:42:21', 'Trigger END', 197, NULL, NULL, NULL, NULL, NULL),
(603, 'insert', '2025-10-03 17:44:36', 'Trigger START', 198, NULL, 'Completo', NULL, NULL, NULL),
(604, 'insert', '2025-10-03 17:44:36', 'After Planificacion SELECT', 198, NULL, NULL, NULL, NULL, NULL),
(605, 'insert', '2025-10-03 17:44:36', 'v_idplanificacion IS NULL', 198, NULL, NULL, NULL, NULL, 0),
(606, 'insert', '2025-10-03 17:44:36', 'Trigger END', 198, NULL, NULL, NULL, NULL, NULL),
(607, 'insert', '2025-10-03 17:46:00', 'Trigger START', 199, NULL, 'Completo', NULL, NULL, NULL),
(608, 'insert', '2025-10-03 17:46:00', 'After Planificacion SELECT', 199, NULL, NULL, NULL, NULL, NULL),
(609, 'insert', '2025-10-03 17:46:00', 'v_idplanificacion IS NULL', 199, NULL, NULL, NULL, NULL, 0),
(610, 'insert', '2025-10-03 17:46:00', 'Trigger END', 199, NULL, NULL, NULL, NULL, NULL),
(611, 'insert', '2025-10-03 17:48:04', 'Trigger START', 200, NULL, 'Programado', NULL, NULL, NULL),
(612, 'insert', '2025-10-03 17:48:04', 'After Planificacion SELECT', 200, NULL, NULL, NULL, NULL, NULL),
(613, 'insert', '2025-10-03 17:48:04', 'v_idplanificacion IS NULL', 200, NULL, NULL, NULL, NULL, 0),
(614, 'insert', '2025-10-03 17:48:04', 'Trigger END', 200, NULL, NULL, NULL, NULL, NULL),
(615, 'insert', '2025-10-03 19:21:53', 'Trigger START', 201, NULL, 'Completo', NULL, NULL, NULL),
(616, 'insert', '2025-10-03 19:21:53', 'After Planificacion SELECT', 201, NULL, NULL, NULL, NULL, NULL),
(617, 'insert', '2025-10-03 19:21:53', 'v_idplanificacion IS NULL', 201, NULL, NULL, NULL, NULL, 0),
(618, 'insert', '2025-10-03 19:21:53', 'Trigger END', 201, NULL, NULL, NULL, NULL, NULL),
(619, 'insert', '2025-10-03 19:31:04', 'Trigger START', 202, NULL, 'En proceso', NULL, NULL, NULL),
(620, 'insert', '2025-10-03 19:31:04', 'After Planificacion SELECT', 202, NULL, NULL, NULL, NULL, NULL),
(621, 'insert', '2025-10-03 19:31:04', 'v_idplanificacion IS NULL', 202, NULL, NULL, NULL, NULL, 0),
(622, 'insert', '2025-10-03 19:31:04', 'Trigger END', 202, NULL, NULL, NULL, NULL, NULL),
(623, 'insert', '2025-10-03 20:03:24', 'Trigger START', 203, NULL, 'Completo', NULL, NULL, NULL),
(624, 'insert', '2025-10-03 20:03:24', 'After Planificacion SELECT', 203, NULL, NULL, NULL, NULL, NULL),
(625, 'insert', '2025-10-03 20:03:24', 'v_idplanificacion IS NULL', 203, NULL, NULL, NULL, NULL, 0),
(626, 'insert', '2025-10-03 20:03:24', 'Trigger END', 203, NULL, NULL, NULL, NULL, NULL),
(627, 'insert', '2025-10-03 20:11:06', 'Trigger START', 204, NULL, 'Completo', NULL, NULL, NULL),
(628, 'insert', '2025-10-03 20:11:06', 'After Planificacion SELECT', 204, NULL, NULL, NULL, NULL, NULL),
(629, 'insert', '2025-10-03 20:11:06', 'v_idplanificacion IS NULL', 204, NULL, NULL, NULL, NULL, 0),
(630, 'insert', '2025-10-03 20:11:06', 'Trigger END', 204, NULL, NULL, NULL, NULL, NULL),
(631, 'insert', '2025-10-03 20:14:57', 'Trigger START', 205, NULL, 'En proceso', NULL, NULL, NULL),
(632, 'insert', '2025-10-03 20:14:57', 'After Planificacion SELECT', 205, NULL, NULL, NULL, NULL, NULL),
(633, 'insert', '2025-10-03 20:14:57', 'v_idplanificacion IS NULL', 205, NULL, NULL, NULL, NULL, 0),
(634, 'insert', '2025-10-03 20:14:57', 'Trigger END', 205, NULL, NULL, NULL, NULL, NULL),
(635, 'insert', '2025-10-03 20:17:30', 'Trigger START', 206, NULL, 'En proceso', NULL, NULL, NULL),
(636, 'insert', '2025-10-03 20:17:30', 'After Planificacion SELECT', 206, NULL, NULL, NULL, NULL, NULL),
(637, 'insert', '2025-10-03 20:17:30', 'v_idplanificacion IS NULL', 206, NULL, NULL, NULL, NULL, 0),
(638, 'insert', '2025-10-03 20:17:30', 'Trigger END', 206, NULL, NULL, NULL, NULL, NULL),
(639, 'insert', '2025-10-03 20:21:14', 'Trigger START', 207, NULL, 'En proceso', NULL, NULL, NULL),
(640, 'insert', '2025-10-03 20:21:14', 'After Planificacion SELECT', 207, NULL, NULL, NULL, NULL, NULL),
(641, 'insert', '2025-10-03 20:21:14', 'v_idplanificacion IS NULL', 207, NULL, NULL, NULL, NULL, 0),
(642, 'insert', '2025-10-03 20:21:14', 'Trigger END', 207, NULL, NULL, NULL, NULL, NULL),
(643, 'insert', '2025-10-06 14:12:27', 'Trigger START', 208, NULL, 'En proceso', NULL, NULL, NULL),
(644, 'insert', '2025-10-06 14:12:27', 'After Planificacion SELECT', 208, NULL, NULL, NULL, NULL, NULL),
(645, 'insert', '2025-10-06 14:12:27', 'v_idplanificacion IS NULL', 208, NULL, NULL, NULL, NULL, 0),
(646, 'insert', '2025-10-06 14:12:27', 'Trigger END', 208, NULL, NULL, NULL, NULL, NULL),
(647, 'insert', '2025-10-06 14:36:40', 'Trigger START', 209, NULL, 'Programado', NULL, NULL, NULL),
(648, 'insert', '2025-10-06 14:36:40', 'After Planificacion SELECT', 209, NULL, NULL, NULL, NULL, NULL),
(649, 'insert', '2025-10-06 14:36:40', 'v_idplanificacion IS NULL', 209, NULL, NULL, NULL, NULL, 0),
(650, 'insert', '2025-10-06 14:36:40', 'Trigger END', 209, NULL, NULL, NULL, NULL, NULL),
(651, 'insert', '2025-10-06 14:41:22', 'Trigger START', 210, NULL, 'En proceso', NULL, NULL, NULL),
(652, 'insert', '2025-10-06 14:41:22', 'After Planificacion SELECT', 210, NULL, NULL, NULL, NULL, NULL),
(653, 'insert', '2025-10-06 14:41:22', 'v_idplanificacion IS NULL', 210, NULL, NULL, NULL, NULL, 0),
(654, 'insert', '2025-10-06 14:41:22', 'Trigger END', 210, NULL, NULL, NULL, NULL, NULL),
(655, 'insert', '2025-10-06 14:47:04', 'Trigger START', 211, NULL, 'En proceso', NULL, NULL, NULL),
(656, 'insert', '2025-10-06 14:47:04', 'After Planificacion SELECT', 211, NULL, NULL, NULL, NULL, NULL),
(657, 'insert', '2025-10-06 14:47:04', 'v_idplanificacion IS NULL', 211, NULL, NULL, NULL, NULL, 0),
(658, 'insert', '2025-10-06 14:47:04', 'Trigger END', 211, NULL, NULL, NULL, NULL, NULL),
(659, 'insert', '2025-10-06 14:48:39', 'Trigger START', 212, NULL, 'En proceso', NULL, NULL, NULL),
(660, 'insert', '2025-10-06 14:48:39', 'After Planificacion SELECT', 212, NULL, NULL, NULL, NULL, NULL),
(661, 'insert', '2025-10-06 14:48:39', 'v_idplanificacion IS NULL', 212, NULL, NULL, NULL, NULL, 0),
(662, 'insert', '2025-10-06 14:48:39', 'Trigger END', 212, NULL, NULL, NULL, NULL, NULL),
(663, 'insert', '2025-10-06 16:11:27', 'Trigger START', 213, NULL, 'En revisión', NULL, NULL, NULL),
(664, 'insert', '2025-10-06 16:11:27', 'After Planificacion SELECT', 213, NULL, NULL, NULL, NULL, NULL),
(665, 'insert', '2025-10-06 16:11:27', 'v_idplanificacion IS NULL', 213, NULL, NULL, NULL, NULL, 0),
(666, 'insert', '2025-10-06 16:11:27', 'Trigger END', 213, NULL, NULL, NULL, NULL, NULL),
(667, 'insert', '2025-10-06 18:31:17', 'Trigger START', 214, NULL, 'Completo', NULL, NULL, NULL),
(668, 'insert', '2025-10-06 18:31:17', 'After Planificacion SELECT', 214, NULL, NULL, NULL, NULL, NULL),
(669, 'insert', '2025-10-06 18:31:17', 'v_idplanificacion IS NULL', 214, NULL, NULL, NULL, NULL, 0),
(670, 'insert', '2025-10-06 18:31:17', 'Trigger END', 214, NULL, NULL, NULL, NULL, NULL),
(671, 'insert', '2025-10-06 21:08:31', 'Trigger START', 215, NULL, 'Completo', NULL, NULL, NULL),
(672, 'insert', '2025-10-06 21:08:31', 'After Planificacion SELECT', 215, NULL, NULL, NULL, NULL, NULL),
(673, 'insert', '2025-10-06 21:08:31', 'v_idplanificacion IS NULL', 215, NULL, NULL, NULL, NULL, 0),
(674, 'insert', '2025-10-06 21:08:31', 'Trigger END', 215, NULL, NULL, NULL, NULL, NULL),
(675, 'insert', '2025-10-07 14:21:31', 'Trigger START', 216, NULL, 'En proceso', NULL, NULL, NULL),
(676, 'insert', '2025-10-07 14:21:31', 'After Planificacion SELECT', 216, NULL, NULL, NULL, NULL, NULL),
(677, 'insert', '2025-10-07 14:21:31', 'v_idplanificacion IS NULL', 216, NULL, NULL, NULL, NULL, 0),
(678, 'insert', '2025-10-07 14:21:31', 'Trigger END', 216, NULL, NULL, NULL, NULL, NULL),
(679, 'insert', '2025-10-07 14:22:35', 'Trigger START', 217, NULL, 'Completo', NULL, NULL, NULL),
(680, 'insert', '2025-10-07 14:22:35', 'After Planificacion SELECT', 217, NULL, NULL, NULL, NULL, NULL),
(681, 'insert', '2025-10-07 14:22:35', 'v_idplanificacion IS NULL', 217, NULL, NULL, NULL, NULL, 0),
(682, 'insert', '2025-10-07 14:22:35', 'Trigger END', 217, NULL, NULL, NULL, NULL, NULL),
(683, 'insert', '2025-10-07 22:13:26', 'Trigger START', 218, NULL, 'En proceso', NULL, NULL, NULL),
(684, 'insert', '2025-10-07 22:13:26', 'After Planificacion SELECT', 218, NULL, NULL, NULL, NULL, NULL),
(685, 'insert', '2025-10-07 22:13:26', 'v_idplanificacion IS NULL', 218, NULL, NULL, NULL, NULL, 0),
(686, 'insert', '2025-10-07 22:13:26', 'Trigger END', 218, NULL, NULL, NULL, NULL, NULL),
(687, 'insert', '2025-10-10 18:19:11', 'Trigger START', 219, NULL, 'En proceso', NULL, NULL, NULL),
(688, 'insert', '2025-10-10 18:19:11', 'After Planificacion SELECT', 219, NULL, NULL, NULL, NULL, NULL),
(689, 'insert', '2025-10-10 18:19:11', 'v_idplanificacion IS NULL', 219, NULL, NULL, NULL, NULL, 0),
(690, 'insert', '2025-10-10 18:19:11', 'Trigger END', 219, NULL, NULL, NULL, NULL, NULL),
(691, 'insert', '2025-10-10 20:51:14', 'Trigger START', 220, NULL, 'En proceso', NULL, NULL, NULL),
(692, 'insert', '2025-10-10 20:51:14', 'After Planificacion SELECT', 220, NULL, NULL, NULL, NULL, NULL),
(693, 'insert', '2025-10-10 20:51:14', 'v_idplanificacion IS NULL', 220, NULL, NULL, NULL, NULL, 0),
(694, 'insert', '2025-10-10 20:51:14', 'Trigger END', 220, NULL, NULL, NULL, NULL, NULL),
(695, 'insert', '2025-10-10 20:54:25', 'Trigger START', 221, NULL, 'En proceso', NULL, NULL, NULL),
(696, 'insert', '2025-10-10 20:54:25', 'After Planificacion SELECT', 221, NULL, NULL, NULL, NULL, NULL),
(697, 'insert', '2025-10-10 20:54:25', 'v_idplanificacion IS NULL', 221, NULL, NULL, NULL, NULL, 0),
(698, 'insert', '2025-10-10 20:54:25', 'Trigger END', 221, NULL, NULL, NULL, NULL, NULL),
(699, 'insert', '2025-10-13 15:12:10', 'Trigger START', 222, NULL, 'Completo', NULL, NULL, NULL),
(700, 'insert', '2025-10-13 15:12:10', 'After Planificacion SELECT', 222, NULL, NULL, NULL, NULL, NULL),
(701, 'insert', '2025-10-13 15:12:10', 'v_idplanificacion IS NULL', 222, NULL, NULL, NULL, NULL, 0),
(702, 'insert', '2025-10-13 15:12:10', 'Trigger END', 222, NULL, NULL, NULL, NULL, NULL),
(703, 'insert', '2025-10-14 22:54:55', 'Trigger START', 223, NULL, 'Completo', NULL, NULL, NULL),
(704, 'insert', '2025-10-14 22:54:55', 'After Planificacion SELECT', 223, NULL, NULL, NULL, NULL, NULL),
(705, 'insert', '2025-10-14 22:54:55', 'v_idplanificacion IS NULL', 223, NULL, NULL, NULL, NULL, 0),
(706, 'insert', '2025-10-14 22:54:55', 'Trigger END', 223, NULL, NULL, NULL, NULL, NULL),
(707, 'insert', '2025-10-14 23:05:04', 'Trigger START', 224, NULL, 'En proceso', NULL, NULL, NULL),
(708, 'insert', '2025-10-14 23:05:04', 'After Planificacion SELECT', 224, NULL, NULL, NULL, NULL, NULL),
(709, 'insert', '2025-10-14 23:05:04', 'v_idplanificacion IS NULL', 224, NULL, NULL, NULL, NULL, 0),
(710, 'insert', '2025-10-14 23:05:04', 'Trigger END', 224, NULL, NULL, NULL, NULL, NULL),
(711, 'insert', '2025-10-14 23:07:21', 'Trigger START', 225, NULL, 'En proceso', NULL, NULL, NULL),
(712, 'insert', '2025-10-14 23:07:21', 'After Planificacion SELECT', 225, NULL, NULL, NULL, NULL, NULL),
(713, 'insert', '2025-10-14 23:07:21', 'v_idplanificacion IS NULL', 225, NULL, NULL, NULL, NULL, 0),
(714, 'insert', '2025-10-14 23:07:21', 'Trigger END', 225, NULL, NULL, NULL, NULL, NULL),
(715, 'insert', '2025-10-16 16:14:46', 'Trigger START', 226, NULL, 'Programado', NULL, NULL, NULL),
(716, 'insert', '2025-10-16 16:14:46', 'After Planificacion SELECT', 226, NULL, NULL, NULL, NULL, NULL),
(717, 'insert', '2025-10-16 16:14:46', 'v_idplanificacion IS NULL', 226, NULL, NULL, NULL, NULL, 0),
(718, 'insert', '2025-10-16 16:14:46', 'Trigger END', 226, NULL, NULL, NULL, NULL, NULL),
(719, 'insert', '2025-10-17 20:13:13', 'Trigger START', 227, NULL, 'En proceso', NULL, NULL, NULL),
(720, 'insert', '2025-10-17 20:13:13', 'After Planificacion SELECT', 227, NULL, NULL, NULL, NULL, NULL),
(721, 'insert', '2025-10-17 20:13:13', 'v_idplanificacion IS NULL', 227, NULL, NULL, NULL, NULL, 0),
(722, 'insert', '2025-10-17 20:13:13', 'Trigger END', 227, NULL, NULL, NULL, NULL, NULL),
(723, 'insert', '2025-10-20 13:37:12', 'Trigger START', 228, NULL, 'En proceso', NULL, NULL, NULL),
(724, 'insert', '2025-10-20 13:37:12', 'After Planificacion SELECT', 228, NULL, NULL, NULL, NULL, NULL),
(725, 'insert', '2025-10-20 13:37:12', 'v_idplanificacion IS NULL', 228, NULL, NULL, NULL, NULL, 0),
(726, 'insert', '2025-10-20 13:37:12', 'Trigger END', 228, NULL, NULL, NULL, NULL, NULL),
(727, 'insert', '2025-10-20 13:39:02', 'Trigger START', 229, NULL, 'En proceso', NULL, NULL, NULL),
(728, 'insert', '2025-10-20 13:39:02', 'After Planificacion SELECT', 229, NULL, NULL, NULL, NULL, NULL),
(729, 'insert', '2025-10-20 13:39:02', 'v_idplanificacion IS NULL', 229, NULL, NULL, NULL, NULL, 0),
(730, 'insert', '2025-10-20 13:39:02', 'Trigger END', 229, NULL, NULL, NULL, NULL, NULL),
(731, 'insert', '2025-10-20 13:39:51', 'Trigger START', 230, NULL, 'Programado', NULL, NULL, NULL),
(732, 'insert', '2025-10-20 13:39:51', 'After Planificacion SELECT', 230, NULL, NULL, NULL, NULL, NULL),
(733, 'insert', '2025-10-20 13:39:51', 'v_idplanificacion IS NULL', 230, NULL, NULL, NULL, NULL, 0),
(734, 'insert', '2025-10-20 13:39:51', 'Trigger END', 230, NULL, NULL, NULL, NULL, NULL),
(735, 'insert', '2025-10-20 13:44:15', 'Trigger START', 231, NULL, 'En proceso', NULL, NULL, NULL),
(736, 'insert', '2025-10-20 13:44:15', 'After Planificacion SELECT', 231, NULL, NULL, NULL, NULL, NULL),
(737, 'insert', '2025-10-20 13:44:15', 'v_idplanificacion IS NULL', 231, NULL, NULL, NULL, NULL, 0),
(738, 'insert', '2025-10-20 13:44:15', 'Trigger END', 231, NULL, NULL, NULL, NULL, NULL),
(739, 'insert', '2025-10-20 18:12:59', 'Trigger START', 232, NULL, 'Completo', NULL, NULL, NULL),
(740, 'insert', '2025-10-20 18:12:59', 'After Planificacion SELECT', 232, NULL, NULL, NULL, NULL, NULL),
(741, 'insert', '2025-10-20 18:12:59', 'v_idplanificacion IS NULL', 232, NULL, NULL, NULL, NULL, 0),
(742, 'insert', '2025-10-20 18:12:59', 'Trigger END', 232, NULL, NULL, NULL, NULL, NULL),
(743, 'insert', '2025-10-21 15:52:10', 'Trigger START', 233, NULL, 'Completo', NULL, NULL, NULL),
(744, 'insert', '2025-10-21 15:52:10', 'After Planificacion SELECT', 233, NULL, NULL, NULL, NULL, NULL),
(745, 'insert', '2025-10-21 15:52:10', 'v_idplanificacion IS NULL', 233, NULL, NULL, NULL, NULL, 0),
(746, 'insert', '2025-10-21 15:52:10', 'Trigger END', 233, NULL, NULL, NULL, NULL, NULL),
(747, 'insert', '2025-10-21 21:42:16', 'Trigger START', 234, NULL, 'Completo', NULL, NULL, NULL),
(748, 'insert', '2025-10-21 21:42:16', 'After Planificacion SELECT', 234, NULL, NULL, NULL, NULL, NULL),
(749, 'insert', '2025-10-21 21:42:16', 'v_idplanificacion IS NULL', 234, NULL, NULL, NULL, NULL, 0),
(750, 'insert', '2025-10-21 21:42:16', 'Trigger END', 234, NULL, NULL, NULL, NULL, NULL),
(751, 'insert', '2025-10-23 14:37:54', 'Trigger START', 235, NULL, 'Programado', NULL, NULL, NULL),
(752, 'insert', '2025-10-23 14:37:54', 'After Planificacion SELECT', 235, NULL, NULL, NULL, NULL, NULL),
(753, 'insert', '2025-10-23 14:37:54', 'v_idplanificacion IS NULL', 235, NULL, NULL, NULL, NULL, 0),
(754, 'insert', '2025-10-23 14:37:54', 'Trigger END', 235, NULL, NULL, NULL, NULL, NULL),
(755, 'insert', '2025-10-24 19:44:22', 'Trigger START', 236, NULL, 'En proceso', NULL, NULL, NULL),
(756, 'insert', '2025-10-24 19:44:22', 'After Planificacion SELECT', 236, NULL, NULL, NULL, NULL, NULL),
(757, 'insert', '2025-10-24 19:44:22', 'v_idplanificacion IS NULL', 236, NULL, NULL, NULL, NULL, 0),
(758, 'insert', '2025-10-24 19:44:22', 'Trigger END', 236, NULL, NULL, NULL, NULL, NULL),
(759, 'insert', '2025-10-24 19:46:14', 'Trigger START', 237, NULL, 'En proceso', NULL, NULL, NULL),
(760, 'insert', '2025-10-24 19:46:14', 'After Planificacion SELECT', 237, NULL, NULL, NULL, NULL, NULL),
(761, 'insert', '2025-10-24 19:46:14', 'v_idplanificacion IS NULL', 237, NULL, NULL, NULL, NULL, 0),
(762, 'insert', '2025-10-24 19:46:14', 'Trigger END', 237, NULL, NULL, NULL, NULL, NULL),
(763, 'insert', '2025-10-24 19:48:08', 'Trigger START', 238, NULL, 'En proceso', NULL, NULL, NULL),
(764, 'insert', '2025-10-24 19:48:08', 'After Planificacion SELECT', 238, NULL, NULL, NULL, NULL, NULL),
(765, 'insert', '2025-10-24 19:48:08', 'v_idplanificacion IS NULL', 238, NULL, NULL, NULL, NULL, 0),
(766, 'insert', '2025-10-24 19:48:08', 'Trigger END', 238, NULL, NULL, NULL, NULL, NULL),
(767, 'insert', '2025-10-24 19:49:22', 'Trigger START', 239, NULL, 'En proceso', NULL, NULL, NULL),
(768, 'insert', '2025-10-24 19:49:22', 'After Planificacion SELECT', 239, NULL, NULL, NULL, NULL, NULL),
(769, 'insert', '2025-10-24 19:49:22', 'v_idplanificacion IS NULL', 239, NULL, NULL, NULL, NULL, 0),
(770, 'insert', '2025-10-24 19:49:22', 'Trigger END', 239, NULL, NULL, NULL, NULL, NULL),
(771, 'insert', '2025-10-24 19:50:56', 'Trigger START', 240, NULL, 'En proceso', NULL, NULL, NULL),
(772, 'insert', '2025-10-24 19:50:56', 'After Planificacion SELECT', 240, NULL, NULL, NULL, NULL, NULL),
(773, 'insert', '2025-10-24 19:50:56', 'v_idplanificacion IS NULL', 240, NULL, NULL, NULL, NULL, 0),
(774, 'insert', '2025-10-24 19:50:56', 'Trigger END', 240, NULL, NULL, NULL, NULL, NULL),
(775, 'insert', '2025-10-24 20:44:30', 'Trigger START', 241, NULL, 'Programado', NULL, NULL, NULL),
(776, 'insert', '2025-10-24 20:44:30', 'After Planificacion SELECT', 241, NULL, NULL, NULL, NULL, NULL),
(777, 'insert', '2025-10-24 20:44:30', 'v_idplanificacion IS NULL', 241, NULL, NULL, NULL, NULL, 0),
(778, 'insert', '2025-10-24 20:44:30', 'Trigger END', 241, NULL, NULL, NULL, NULL, NULL),
(779, 'insert', '2025-10-27 16:37:34', 'Trigger START', 242, NULL, 'Completo', NULL, NULL, NULL),
(780, 'insert', '2025-10-27 16:37:34', 'After Planificacion SELECT', 242, NULL, NULL, NULL, NULL, NULL),
(781, 'insert', '2025-10-27 16:37:34', 'v_idplanificacion IS NULL', 242, NULL, NULL, NULL, NULL, 0),
(782, 'insert', '2025-10-27 16:37:34', 'Trigger END', 242, NULL, NULL, NULL, NULL, NULL),
(783, 'insert', '2025-10-29 23:35:29', 'Trigger START', 243, NULL, 'Completo', NULL, NULL, NULL),
(784, 'insert', '2025-10-29 23:35:29', 'After Planificacion SELECT', 243, NULL, NULL, NULL, NULL, NULL),
(785, 'insert', '2025-10-29 23:35:29', 'v_idplanificacion IS NULL', 243, NULL, NULL, NULL, NULL, 0),
(786, 'insert', '2025-10-29 23:35:29', 'Trigger END', 243, NULL, NULL, NULL, NULL, NULL),
(787, 'insert', '2025-10-30 15:35:24', 'Trigger START', 244, NULL, 'Completo', NULL, NULL, NULL),
(788, 'insert', '2025-10-30 15:35:24', 'After Planificacion SELECT', 244, NULL, NULL, NULL, NULL, NULL),
(789, 'insert', '2025-10-30 15:35:24', 'v_idplanificacion IS NULL', 244, NULL, NULL, NULL, NULL, 0),
(790, 'insert', '2025-10-30 15:35:24', 'Trigger END', 244, NULL, NULL, NULL, NULL, NULL),
(791, 'insert', '2025-10-30 15:36:24', 'Trigger START', 245, NULL, 'Completo', NULL, NULL, NULL),
(792, 'insert', '2025-10-30 15:36:24', 'After Planificacion SELECT', 245, NULL, NULL, NULL, NULL, NULL),
(793, 'insert', '2025-10-30 15:36:24', 'v_idplanificacion IS NULL', 245, NULL, NULL, NULL, NULL, 0),
(794, 'insert', '2025-10-30 15:36:24', 'Trigger END', 245, NULL, NULL, NULL, NULL, NULL),
(795, 'insert', '2025-10-30 15:38:25', 'Trigger START', 246, NULL, 'Completo', NULL, NULL, NULL),
(796, 'insert', '2025-10-30 15:38:25', 'After Planificacion SELECT', 246, NULL, NULL, NULL, NULL, NULL),
(797, 'insert', '2025-10-30 15:38:25', 'v_idplanificacion IS NULL', 246, NULL, NULL, NULL, NULL, 0),
(798, 'insert', '2025-10-30 15:38:25', 'Trigger END', 246, NULL, NULL, NULL, NULL, NULL),
(799, 'insert', '2025-10-30 18:22:31', 'Trigger START', 247, NULL, 'Completo', NULL, NULL, NULL),
(800, 'insert', '2025-10-30 18:22:31', 'After Planificacion SELECT', 247, NULL, NULL, NULL, NULL, NULL),
(801, 'insert', '2025-10-30 18:22:31', 'v_idplanificacion IS NULL', 247, NULL, NULL, NULL, NULL, 0),
(802, 'insert', '2025-10-30 18:22:31', 'Trigger END', 247, NULL, NULL, NULL, NULL, NULL),
(803, 'insert', '2025-10-31 16:50:21', 'Trigger START', 248, NULL, 'En proceso', NULL, NULL, NULL),
(804, 'insert', '2025-10-31 16:50:21', 'After Planificacion SELECT', 248, NULL, NULL, NULL, NULL, NULL),
(805, 'insert', '2025-10-31 16:50:21', 'v_idplanificacion IS NULL', 248, NULL, NULL, NULL, NULL, 0),
(806, 'insert', '2025-10-31 16:50:21', 'Trigger END', 248, NULL, NULL, NULL, NULL, NULL),
(807, 'insert', '2025-10-31 19:04:02', 'Trigger START', 249, NULL, 'Completo', NULL, NULL, NULL),
(808, 'insert', '2025-10-31 19:04:02', 'After Planificacion SELECT', 249, NULL, NULL, NULL, NULL, NULL),
(809, 'insert', '2025-10-31 19:04:02', 'v_idplanificacion IS NULL', 249, NULL, NULL, NULL, NULL, 0),
(810, 'insert', '2025-10-31 19:04:02', 'Trigger END', 249, NULL, NULL, NULL, NULL, NULL),
(811, 'insert', '2025-10-31 22:09:57', 'Trigger START', 250, NULL, 'Completo', NULL, NULL, NULL),
(812, 'insert', '2025-10-31 22:09:57', 'After Planificacion SELECT', 250, NULL, NULL, NULL, NULL, NULL),
(813, 'insert', '2025-10-31 22:09:57', 'v_idplanificacion IS NULL', 250, NULL, NULL, NULL, NULL, 0),
(814, 'insert', '2025-10-31 22:09:57', 'Trigger END', 250, NULL, NULL, NULL, NULL, NULL),
(815, 'insert', '2025-10-31 23:43:20', 'Trigger START', 251, NULL, 'En proceso', NULL, NULL, NULL),
(816, 'insert', '2025-10-31 23:43:20', 'After Planificacion SELECT', 251, NULL, NULL, NULL, NULL, NULL),
(817, 'insert', '2025-10-31 23:43:20', 'v_idplanificacion IS NULL', 251, NULL, NULL, NULL, NULL, 0),
(818, 'insert', '2025-10-31 23:43:20', 'Trigger END', 251, NULL, NULL, NULL, NULL, NULL),
(819, 'insert', '2025-11-03 15:02:29', 'Trigger START', 252, NULL, 'Completo', NULL, NULL, NULL),
(820, 'insert', '2025-11-03 15:02:29', 'After Planificacion SELECT', 252, NULL, NULL, NULL, NULL, NULL),
(821, 'insert', '2025-11-03 15:02:29', 'v_idplanificacion IS NULL', 252, NULL, NULL, NULL, NULL, 0),
(822, 'insert', '2025-11-03 15:02:29', 'Trigger END', 252, NULL, NULL, NULL, NULL, NULL),
(823, 'insert', '2025-11-05 21:33:26', 'Trigger START', 253, NULL, 'Completo', NULL, NULL, NULL),
(824, 'insert', '2025-11-05 21:33:26', 'After Planificacion SELECT', 253, NULL, NULL, NULL, NULL, NULL),
(825, 'insert', '2025-11-05 21:33:26', 'v_idplanificacion IS NULL', 253, NULL, NULL, NULL, NULL, 0),
(826, 'insert', '2025-11-05 21:33:26', 'Trigger END', 253, NULL, NULL, NULL, NULL, NULL),
(827, 'insert', '2025-11-06 17:49:49', 'Trigger START', 254, NULL, 'En revisión', NULL, NULL, NULL),
(828, 'insert', '2025-11-06 17:49:49', 'After Planificacion SELECT', 254, NULL, NULL, NULL, NULL, NULL),
(829, 'insert', '2025-11-06 17:49:49', 'v_idplanificacion IS NULL', 254, NULL, NULL, NULL, NULL, 0),
(830, 'insert', '2025-11-06 17:49:49', 'Trigger END', 254, NULL, NULL, NULL, NULL, NULL),
(831, 'insert', '2025-11-06 17:51:56', 'Trigger START', 255, NULL, 'En proceso', NULL, NULL, NULL),
(832, 'insert', '2025-11-06 17:51:56', 'After Planificacion SELECT', 255, NULL, NULL, NULL, NULL, NULL),
(833, 'insert', '2025-11-06 17:51:56', 'v_idplanificacion IS NULL', 255, NULL, NULL, NULL, NULL, 0),
(834, 'insert', '2025-11-06 17:51:56', 'Trigger END', 255, NULL, NULL, NULL, NULL, NULL),
(835, 'insert', '2025-11-07 16:50:26', 'Trigger START', 256, NULL, 'En proceso', NULL, NULL, NULL),
(836, 'insert', '2025-11-07 16:50:26', 'After Planificacion SELECT', 256, NULL, NULL, NULL, NULL, NULL),
(837, 'insert', '2025-11-07 16:50:26', 'v_idplanificacion IS NULL', 256, NULL, NULL, NULL, NULL, 0),
(838, 'insert', '2025-11-07 16:50:26', 'Trigger END', 256, NULL, NULL, NULL, NULL, NULL),
(839, 'insert', '2025-11-07 16:52:41', 'Trigger START', 257, NULL, 'Programado', NULL, NULL, NULL),
(840, 'insert', '2025-11-07 16:52:41', 'After Planificacion SELECT', 257, NULL, NULL, NULL, NULL, NULL),
(841, 'insert', '2025-11-07 16:52:41', 'v_idplanificacion IS NULL', 257, NULL, NULL, NULL, NULL, 0),
(842, 'insert', '2025-11-07 16:52:41', 'Trigger END', 257, NULL, NULL, NULL, NULL, NULL),
(843, 'insert', '2025-11-07 18:58:48', 'Trigger START', 258, NULL, 'En proceso', NULL, NULL, NULL),
(844, 'insert', '2025-11-07 18:58:48', 'After Planificacion SELECT', 258, NULL, NULL, NULL, NULL, NULL),
(845, 'insert', '2025-11-07 18:58:48', 'v_idplanificacion IS NULL', 258, NULL, NULL, NULL, NULL, 0),
(846, 'insert', '2025-11-07 18:58:48', 'Trigger END', 258, NULL, NULL, NULL, NULL, NULL),
(847, 'insert', '2025-11-07 22:41:47', 'Trigger START', 259, NULL, 'En proceso', NULL, NULL, NULL),
(848, 'insert', '2025-11-07 22:41:47', 'After Planificacion SELECT', 259, NULL, NULL, NULL, NULL, NULL),
(849, 'insert', '2025-11-07 22:41:47', 'v_idplanificacion IS NULL', 259, NULL, NULL, NULL, NULL, 0),
(850, 'insert', '2025-11-07 22:41:47', 'Trigger END', 259, NULL, NULL, NULL, NULL, NULL),
(851, 'insert', '2025-11-07 22:44:56', 'Trigger START', 260, NULL, 'Programado', NULL, NULL, NULL),
(852, 'insert', '2025-11-07 22:44:56', 'After Planificacion SELECT', 260, NULL, NULL, NULL, NULL, NULL),
(853, 'insert', '2025-11-07 22:44:56', 'v_idplanificacion IS NULL', 260, NULL, NULL, NULL, NULL, 0),
(854, 'insert', '2025-11-07 22:44:56', 'Trigger END', 260, NULL, NULL, NULL, NULL, NULL),
(855, 'insert', '2025-11-07 22:49:54', 'Trigger START', 261, NULL, 'En proceso', NULL, NULL, NULL),
(856, 'insert', '2025-11-07 22:49:54', 'After Planificacion SELECT', 261, NULL, NULL, NULL, NULL, NULL),
(857, 'insert', '2025-11-07 22:49:54', 'v_idplanificacion IS NULL', 261, NULL, NULL, NULL, NULL, 0),
(858, 'insert', '2025-11-07 22:49:54', 'Trigger END', 261, NULL, NULL, NULL, NULL, NULL),
(859, 'insert', '2025-11-07 23:40:10', 'Trigger START', 262, NULL, 'En proceso', NULL, NULL, NULL),
(860, 'insert', '2025-11-07 23:40:10', 'After Planificacion SELECT', 262, NULL, NULL, NULL, NULL, NULL),
(861, 'insert', '2025-11-07 23:40:10', 'v_idplanificacion IS NULL', 262, NULL, NULL, NULL, NULL, 0),
(862, 'insert', '2025-11-07 23:40:10', 'Trigger END', 262, NULL, NULL, NULL, NULL, NULL),
(863, 'insert', '2025-11-10 13:42:52', 'Trigger START', 263, NULL, 'En proceso', NULL, NULL, NULL),
(864, 'insert', '2025-11-10 13:42:52', 'After Planificacion SELECT', 263, NULL, NULL, NULL, NULL, NULL),
(865, 'insert', '2025-11-10 13:42:52', 'v_idplanificacion IS NULL', 263, NULL, NULL, NULL, NULL, 0),
(866, 'insert', '2025-11-10 13:42:52', 'Trigger END', 263, NULL, NULL, NULL, NULL, NULL),
(867, 'insert', '2025-11-10 13:44:47', 'Trigger START', 264, NULL, 'En proceso', NULL, NULL, NULL),
(868, 'insert', '2025-11-10 13:44:47', 'After Planificacion SELECT', 264, NULL, NULL, NULL, NULL, NULL),
(869, 'insert', '2025-11-10 13:44:47', 'v_idplanificacion IS NULL', 264, NULL, NULL, NULL, NULL, 0),
(870, 'insert', '2025-11-10 13:44:47', 'Trigger END', 264, NULL, NULL, NULL, NULL, NULL),
(871, 'insert', '2025-11-10 13:51:08', 'Trigger START', 265, NULL, 'Completo', NULL, NULL, NULL),
(872, 'insert', '2025-11-10 13:51:08', 'After Planificacion SELECT', 265, NULL, NULL, NULL, NULL, NULL),
(873, 'insert', '2025-11-10 13:51:08', 'v_idplanificacion IS NULL', 265, NULL, NULL, NULL, NULL, 0),
(874, 'insert', '2025-11-10 13:51:08', 'Trigger END', 265, NULL, NULL, NULL, NULL, NULL),
(875, 'insert', '2025-11-12 14:32:06', 'Trigger START', 266, NULL, 'En proceso', NULL, NULL, NULL),
(876, 'insert', '2025-11-12 14:32:06', 'After Planificacion SELECT', 266, NULL, NULL, NULL, NULL, NULL),
(877, 'insert', '2025-11-12 14:32:06', 'v_idplanificacion IS NULL', 266, NULL, NULL, NULL, NULL, 0),
(878, 'insert', '2025-11-12 14:32:06', 'Trigger END', 266, NULL, NULL, NULL, NULL, NULL),
(879, 'insert', '2025-11-14 15:27:36', 'Trigger START', 267, NULL, 'Completo', NULL, NULL, NULL),
(880, 'insert', '2025-11-14 15:27:36', 'After Planificacion SELECT', 267, NULL, NULL, NULL, NULL, NULL),
(881, 'insert', '2025-11-14 15:27:36', 'v_idplanificacion IS NULL', 267, NULL, NULL, NULL, NULL, 0),
(882, 'insert', '2025-11-14 15:27:36', 'Trigger END', 267, NULL, NULL, NULL, NULL, NULL),
(883, 'insert', '2025-11-14 18:16:53', 'Trigger START', 268, NULL, 'Completo', NULL, NULL, NULL),
(884, 'insert', '2025-11-14 18:16:53', 'After Planificacion SELECT', 268, NULL, NULL, NULL, NULL, NULL),
(885, 'insert', '2025-11-14 18:16:53', 'v_idplanificacion IS NULL', 268, NULL, NULL, NULL, NULL, 0),
(886, 'insert', '2025-11-14 18:16:53', 'Trigger END', 268, NULL, NULL, NULL, NULL, NULL),
(887, 'insert', '2025-11-15 01:10:31', 'Trigger START', 269, NULL, 'En proceso', NULL, NULL, NULL),
(888, 'insert', '2025-11-15 01:10:31', 'After Planificacion SELECT', 269, NULL, NULL, NULL, NULL, NULL),
(889, 'insert', '2025-11-15 01:10:31', 'v_idplanificacion IS NULL', 269, NULL, NULL, NULL, NULL, 0),
(890, 'insert', '2025-11-15 01:10:31', 'Trigger END', 269, NULL, NULL, NULL, NULL, NULL),
(891, 'insert', '2025-11-15 01:13:56', 'Trigger START', 270, NULL, 'En proceso', NULL, NULL, NULL),
(892, 'insert', '2025-11-15 01:13:56', 'After Planificacion SELECT', 270, NULL, NULL, NULL, NULL, NULL),
(893, 'insert', '2025-11-15 01:13:56', 'v_idplanificacion IS NULL', 270, NULL, NULL, NULL, NULL, 0),
(894, 'insert', '2025-11-15 01:13:56', 'Trigger END', 270, NULL, NULL, NULL, NULL, NULL),
(895, 'insert', '2025-11-17 13:34:11', 'Trigger START', 271, NULL, 'En proceso', NULL, NULL, NULL),
(896, 'insert', '2025-11-17 13:34:11', 'After Planificacion SELECT', 271, NULL, NULL, NULL, NULL, NULL),
(897, 'insert', '2025-11-17 13:34:11', 'v_idplanificacion IS NULL', 271, NULL, NULL, NULL, NULL, 0),
(898, 'insert', '2025-11-17 13:34:11', 'Trigger END', 271, NULL, NULL, NULL, NULL, NULL),
(899, 'insert', '2025-11-17 21:25:58', 'Trigger START', 272, NULL, 'En proceso', NULL, NULL, NULL),
(900, 'insert', '2025-11-17 21:25:58', 'After Planificacion SELECT', 272, NULL, NULL, NULL, NULL, NULL),
(901, 'insert', '2025-11-17 21:25:58', 'v_idplanificacion IS NULL', 272, NULL, NULL, NULL, NULL, 0),
(902, 'insert', '2025-11-17 21:25:58', 'Trigger END', 272, NULL, NULL, NULL, NULL, NULL),
(903, 'insert', '2025-11-18 23:01:24', 'Trigger START', 273, NULL, 'En proceso', NULL, NULL, NULL),
(904, 'insert', '2025-11-18 23:01:24', 'After Planificacion SELECT', 273, NULL, NULL, NULL, NULL, NULL),
(905, 'insert', '2025-11-18 23:01:24', 'v_idplanificacion IS NULL', 273, NULL, NULL, NULL, NULL, 0),
(906, 'insert', '2025-11-18 23:01:24', 'Trigger END', 273, NULL, NULL, NULL, NULL, NULL),
(907, 'insert', '2025-11-21 22:14:29', 'Trigger START', 274, NULL, 'En proceso', NULL, NULL, NULL),
(908, 'insert', '2025-11-21 22:14:29', 'After Planificacion SELECT', 274, NULL, NULL, 47, NULL, NULL),
(909, 'insert', '2025-11-21 22:14:29', 'After detalles_planificacion INSERT', 274, 398, 'En proceso', NULL, NULL, NULL),
(910, 'insert', '2025-11-21 22:14:29', 'CONDITION NOT MET for distrib_planif', 274, 398, 'En proceso', NULL, NULL, 0),
(911, 'insert', '2025-11-21 22:14:29', 'Trigger END', 274, NULL, NULL, NULL, NULL, NULL),
(912, 'insert', '2025-11-21 22:50:01', 'Trigger START', 275, NULL, 'En proceso', NULL, NULL, NULL),
(913, 'insert', '2025-11-21 22:50:01', 'After Planificacion SELECT', 275, NULL, NULL, 40, NULL, NULL),
(914, 'insert', '2025-11-21 22:50:01', 'After detalles_planificacion INSERT', 275, 399, 'En proceso', NULL, NULL, NULL),
(915, 'insert', '2025-11-21 22:50:01', 'CONDITION NOT MET for distrib_planif', 275, 399, 'En proceso', NULL, NULL, 0),
(916, 'insert', '2025-11-21 22:50:01', 'Trigger END', 275, NULL, NULL, NULL, NULL, NULL),
(917, 'insert', '2025-11-21 22:55:00', 'Trigger START', 276, NULL, 'En revisión', NULL, NULL, NULL),
(918, 'insert', '2025-11-21 22:55:00', 'After Planificacion SELECT', 276, NULL, NULL, 47, NULL, NULL),
(919, 'insert', '2025-11-21 22:55:00', 'After detalles_planificacion INSERT', 276, 400, 'En revisión', NULL, NULL, NULL),
(920, 'insert', '2025-11-21 22:55:00', 'CONDITION NOT MET for distrib_planif', 276, 400, 'En revisión', NULL, NULL, 0),
(921, 'insert', '2025-11-21 22:55:00', 'Trigger END', 276, NULL, NULL, NULL, NULL, NULL),
(922, 'insert', '2025-11-25 14:00:33', 'Trigger START', 277, NULL, 'En revisión', NULL, NULL, NULL),
(923, 'insert', '2025-11-25 14:00:33', 'After Planificacion SELECT', 277, NULL, NULL, 43, NULL, NULL),
(924, 'insert', '2025-11-25 14:00:33', 'After detalles_planificacion INSERT', 277, 401, 'En revisión', NULL, NULL, NULL),
(925, 'insert', '2025-11-25 14:00:33', 'CONDITION NOT MET for distrib_planif', 277, 401, 'En revisión', NULL, NULL, 0),
(926, 'insert', '2025-11-25 14:00:33', 'Trigger END', 277, NULL, NULL, NULL, NULL, NULL),
(927, 'insert', '2025-11-26 14:04:27', 'Trigger START', 278, NULL, 'En proceso', NULL, NULL, NULL),
(928, 'insert', '2025-11-26 14:04:27', 'After Planificacion SELECT', 278, NULL, NULL, 47, NULL, NULL),
(929, 'insert', '2025-11-26 14:04:27', 'After detalles_planificacion INSERT', 278, 402, 'En proceso', NULL, NULL, NULL),
(930, 'insert', '2025-11-26 14:04:27', 'CONDITION NOT MET for distrib_planif', 278, 402, 'En proceso', NULL, NULL, 0),
(931, 'insert', '2025-11-26 14:04:27', 'Trigger END', 278, NULL, NULL, NULL, NULL, NULL),
(932, 'insert', '2025-11-27 20:31:41', 'Trigger START', 279, NULL, 'Completo', NULL, NULL, NULL),
(933, 'insert', '2025-11-27 20:31:41', 'After Planificacion SELECT', 279, NULL, NULL, 43, NULL, NULL),
(934, 'insert', '2025-11-27 20:31:41', 'After detalles_planificacion INSERT', 279, 403, 'Completo', NULL, NULL, NULL),
(935, 'insert', '2025-11-27 20:31:41', 'CONDITION MET for distrib_planif', 279, 403, 'Completo', NULL, NULL, 0),
(936, 'insert', '2025-11-27 20:31:41', 'Count from distribucionhora', 279, NULL, NULL, NULL, 0, NULL),
(937, 'insert', '2025-11-27 20:31:41', 'Skipped INSERT (no rows in distribucionhora)', 279, NULL, NULL, NULL, 0, 0),
(938, 'insert', '2025-11-27 20:31:41', 'Trigger END', 279, NULL, NULL, NULL, NULL, NULL),
(939, 'insert', '2025-11-27 20:32:43', 'Trigger START', 280, NULL, 'Completo', NULL, NULL, NULL),
(940, 'insert', '2025-11-27 20:32:43', 'After Planificacion SELECT', 280, NULL, NULL, 43, NULL, NULL),
(941, 'insert', '2025-11-27 20:32:43', 'After detalles_planificacion INSERT', 280, 404, 'Completo', NULL, NULL, NULL),
(942, 'insert', '2025-11-27 20:32:43', 'CONDITION MET for distrib_planif', 280, 404, 'Completo', NULL, NULL, 0),
(943, 'insert', '2025-11-27 20:32:43', 'Count from distribucionhora', 280, NULL, NULL, NULL, 0, NULL),
(944, 'insert', '2025-11-27 20:32:43', 'Skipped INSERT (no rows in distribucionhora)', 280, NULL, NULL, NULL, 0, 0),
(945, 'insert', '2025-11-27 20:32:43', 'Trigger END', 280, NULL, NULL, NULL, NULL, NULL),
(946, 'insert', '2025-11-27 20:36:55', 'Trigger START', 281, NULL, 'Completo', NULL, NULL, NULL),
(947, 'insert', '2025-11-27 20:36:55', 'After Planificacion SELECT', 281, NULL, NULL, 43, NULL, NULL),
(948, 'insert', '2025-11-27 20:36:55', 'After detalles_planificacion INSERT', 281, 405, 'Completo', NULL, NULL, NULL),
(949, 'insert', '2025-11-27 20:36:55', 'CONDITION MET for distrib_planif', 281, 405, 'Completo', NULL, NULL, 0),
(950, 'insert', '2025-11-27 20:36:55', 'Count from distribucionhora', 281, NULL, NULL, NULL, 0, NULL),
(951, 'insert', '2025-11-27 20:36:55', 'Skipped INSERT (no rows in distribucionhora)', 281, NULL, NULL, NULL, 0, 0),
(952, 'insert', '2025-11-27 20:36:55', 'Trigger END', 281, NULL, NULL, NULL, NULL, NULL),
(953, 'insert', '2025-11-27 20:58:16', 'Trigger START', 282, NULL, 'Completo', NULL, NULL, NULL),
(954, 'insert', '2025-11-27 20:58:16', 'After Planificacion SELECT', 282, NULL, NULL, 45, NULL, NULL),
(955, 'insert', '2025-11-27 20:58:16', 'After detalles_planificacion INSERT', 282, 406, 'Completo', NULL, NULL, NULL),
(956, 'insert', '2025-11-27 20:58:16', 'CONDITION MET for distrib_planif', 282, 406, 'Completo', NULL, NULL, 0),
(957, 'insert', '2025-11-27 20:58:16', 'Count from distribucionhora', 282, NULL, NULL, NULL, 0, NULL),
(958, 'insert', '2025-11-27 20:58:16', 'Skipped INSERT (no rows in distribucionhora)', 282, NULL, NULL, NULL, 0, 0),
(959, 'insert', '2025-11-27 20:58:16', 'Trigger END', 282, NULL, NULL, NULL, NULL, NULL),
(960, 'insert', '2025-11-27 21:26:52', 'Trigger START', 283, NULL, 'Completo', NULL, NULL, NULL),
(961, 'insert', '2025-11-27 21:26:52', 'After Planificacion SELECT', 283, NULL, NULL, 45, NULL, NULL),
(962, 'insert', '2025-11-27 21:26:52', 'After detalles_planificacion INSERT', 283, 407, 'Completo', NULL, NULL, NULL),
(963, 'insert', '2025-11-27 21:26:52', 'CONDITION MET for distrib_planif', 283, 407, 'Completo', NULL, NULL, 0),
(964, 'insert', '2025-11-27 21:26:52', 'Count from distribucionhora', 283, NULL, NULL, NULL, 0, NULL),
(965, 'insert', '2025-11-27 21:26:52', 'Skipped INSERT (no rows in distribucionhora)', 283, NULL, NULL, NULL, 0, 0),
(966, 'insert', '2025-11-27 21:26:52', 'Trigger END', 283, NULL, NULL, NULL, NULL, NULL),
(967, 'insert', '2025-11-28 16:56:34', 'Trigger START', 284, NULL, 'Completo', NULL, NULL, NULL),
(968, 'insert', '2025-11-28 16:56:34', 'After Planificacion SELECT', 284, NULL, NULL, 45, NULL, NULL),
(969, 'insert', '2025-11-28 16:56:34', 'After detalles_planificacion INSERT', 284, 408, 'Completo', NULL, NULL, NULL),
(970, 'insert', '2025-11-28 16:56:34', 'CONDITION MET for distrib_planif', 284, 408, 'Completo', NULL, NULL, 0),
(971, 'insert', '2025-11-28 16:56:34', 'Count from distribucionhora', 284, NULL, NULL, NULL, 0, NULL),
(972, 'insert', '2025-11-28 16:56:34', 'Skipped INSERT (no rows in distribucionhora)', 284, NULL, NULL, NULL, 0, 0),
(973, 'insert', '2025-11-28 16:56:34', 'Trigger END', 284, NULL, NULL, NULL, NULL, NULL),
(974, 'insert', '2025-11-28 17:00:34', 'Trigger START', 285, NULL, 'Completo', NULL, NULL, NULL),
(975, 'insert', '2025-11-28 17:00:34', 'After Planificacion SELECT', 285, NULL, NULL, 40, NULL, NULL),
(976, 'insert', '2025-11-28 17:00:34', 'After detalles_planificacion INSERT', 285, 409, 'Completo', NULL, NULL, NULL),
(977, 'insert', '2025-11-28 17:00:34', 'CONDITION MET for distrib_planif', 285, 409, 'Completo', NULL, NULL, 0),
(978, 'insert', '2025-11-28 17:00:34', 'Count from distribucionhora', 285, NULL, NULL, NULL, 0, NULL),
(979, 'insert', '2025-11-28 17:00:34', 'Skipped INSERT (no rows in distribucionhora)', 285, NULL, NULL, NULL, 0, 0),
(980, 'insert', '2025-11-28 17:00:34', 'Trigger END', 285, NULL, NULL, NULL, NULL, NULL),
(981, 'insert', '2025-11-28 17:54:58', 'Trigger START', 286, NULL, 'Completo', NULL, NULL, NULL),
(982, 'insert', '2025-11-28 17:54:58', 'After Planificacion SELECT', 286, NULL, NULL, 41, NULL, NULL),
(983, 'insert', '2025-11-28 17:54:58', 'After detalles_planificacion INSERT', 286, 410, 'Completo', NULL, NULL, NULL),
(984, 'insert', '2025-11-28 17:54:58', 'CONDITION MET for distrib_planif', 286, 410, 'Completo', NULL, NULL, 0),
(985, 'insert', '2025-11-28 17:54:58', 'Count from distribucionhora', 286, NULL, NULL, NULL, 0, NULL),
(986, 'insert', '2025-11-28 17:54:58', 'Skipped INSERT (no rows in distribucionhora)', 286, NULL, NULL, NULL, 0, 0),
(987, 'insert', '2025-11-28 17:54:58', 'Trigger END', 286, NULL, NULL, NULL, NULL, NULL),
(988, 'insert', '2025-11-28 17:58:00', 'Trigger START', 287, NULL, 'Completo', NULL, NULL, NULL),
(989, 'insert', '2025-11-28 17:58:00', 'After Planificacion SELECT', 287, NULL, NULL, 44, NULL, NULL),
(990, 'insert', '2025-11-28 17:58:00', 'After detalles_planificacion INSERT', 287, 411, 'Completo', NULL, NULL, NULL),
(991, 'insert', '2025-11-28 17:58:00', 'CONDITION MET for distrib_planif', 287, 411, 'Completo', NULL, NULL, 0),
(992, 'insert', '2025-11-28 17:58:00', 'Count from distribucionhora', 287, NULL, NULL, NULL, 0, NULL),
(993, 'insert', '2025-11-28 17:58:00', 'Skipped INSERT (no rows in distribucionhora)', 287, NULL, NULL, NULL, 0, 0),
(994, 'insert', '2025-11-28 17:58:00', 'Trigger END', 287, NULL, NULL, NULL, NULL, NULL),
(995, 'insert', '2025-11-28 20:05:57', 'Trigger START', 288, NULL, 'Completo', NULL, NULL, NULL),
(996, 'insert', '2025-11-28 20:05:57', 'After Planificacion SELECT', 288, NULL, NULL, 43, NULL, NULL);
INSERT INTO `trigger_debug_log` (`log_id`, `trigger_name`, `log_timestamp`, `message`, `idliquidacion_val`, `iddetalle_val`, `estado_val`, `planificacion_id_val`, `distribucionhora_count`, `insert_attempted`) VALUES
(997, 'insert', '2025-11-28 20:05:57', 'After detalles_planificacion INSERT', 288, 412, 'Completo', NULL, NULL, NULL),
(998, 'insert', '2025-11-28 20:05:57', 'CONDITION MET for distrib_planif', 288, 412, 'Completo', NULL, NULL, 0),
(999, 'insert', '2025-11-28 20:05:57', 'Count from distribucionhora', 288, NULL, NULL, NULL, 0, NULL),
(1000, 'insert', '2025-11-28 20:05:57', 'Skipped INSERT (no rows in distribucionhora)', 288, NULL, NULL, NULL, 0, 0),
(1001, 'insert', '2025-11-28 20:05:57', 'Trigger END', 288, NULL, NULL, NULL, NULL, NULL),
(1002, 'insert', '2025-11-28 20:07:04', 'Trigger START', 289, NULL, 'Completo', NULL, NULL, NULL),
(1003, 'insert', '2025-11-28 20:07:04', 'After Planificacion SELECT', 289, NULL, NULL, 43, NULL, NULL),
(1004, 'insert', '2025-11-28 20:07:04', 'After detalles_planificacion INSERT', 289, 413, 'Completo', NULL, NULL, NULL),
(1005, 'insert', '2025-11-28 20:07:04', 'CONDITION MET for distrib_planif', 289, 413, 'Completo', NULL, NULL, 0),
(1006, 'insert', '2025-11-28 20:07:04', 'Count from distribucionhora', 289, NULL, NULL, NULL, 0, NULL),
(1007, 'insert', '2025-11-28 20:07:04', 'Skipped INSERT (no rows in distribucionhora)', 289, NULL, NULL, NULL, 0, 0),
(1008, 'insert', '2025-11-28 20:07:04', 'Trigger END', 289, NULL, NULL, NULL, NULL, NULL),
(1009, 'insert', '2025-11-28 23:17:36', 'Trigger START', 290, NULL, 'Completo', NULL, NULL, NULL),
(1010, 'insert', '2025-11-28 23:17:36', 'After Planificacion SELECT', 290, NULL, NULL, 42, NULL, NULL),
(1011, 'insert', '2025-11-28 23:17:36', 'After detalles_planificacion INSERT', 290, 414, 'Completo', NULL, NULL, NULL),
(1012, 'insert', '2025-11-28 23:17:36', 'CONDITION MET for distrib_planif', 290, 414, 'Completo', NULL, NULL, 0),
(1013, 'insert', '2025-11-28 23:17:36', 'Count from distribucionhora', 290, NULL, NULL, NULL, 0, NULL),
(1014, 'insert', '2025-11-28 23:17:36', 'Skipped INSERT (no rows in distribucionhora)', 290, NULL, NULL, NULL, 0, 0),
(1015, 'insert', '2025-11-28 23:17:36', 'Trigger END', 290, NULL, NULL, NULL, NULL, NULL),
(1016, 'insert', '2025-12-01 16:13:54', 'Trigger START', 291, NULL, 'Completo', NULL, NULL, NULL),
(1017, 'insert', '2025-12-01 16:13:54', 'After Planificacion SELECT', 291, NULL, NULL, 43, NULL, NULL),
(1018, 'insert', '2025-12-01 16:13:54', 'After detalles_planificacion INSERT', 291, 415, 'Completo', NULL, NULL, NULL),
(1019, 'insert', '2025-12-01 16:13:54', 'CONDITION MET for distrib_planif', 291, 415, 'Completo', NULL, NULL, 0),
(1020, 'insert', '2025-12-01 16:13:54', 'Count from distribucionhora', 291, NULL, NULL, NULL, 0, NULL),
(1021, 'insert', '2025-12-01 16:13:54', 'Skipped INSERT (no rows in distribucionhora)', 291, NULL, NULL, NULL, 0, 0),
(1022, 'insert', '2025-12-01 16:13:54', 'Trigger END', 291, NULL, NULL, NULL, NULL, NULL),
(1023, 'insert', '2025-12-01 19:27:44', 'Trigger START', 292, NULL, 'En proceso', NULL, NULL, NULL),
(1024, 'insert', '2025-12-01 19:27:44', 'After Planificacion SELECT', 292, NULL, NULL, 51, NULL, NULL),
(1025, 'insert', '2025-12-01 19:27:44', 'After detalles_planificacion INSERT', 292, 416, 'En proceso', NULL, NULL, NULL),
(1026, 'insert', '2025-12-01 19:27:44', 'CONDITION NOT MET for distrib_planif', 292, 416, 'En proceso', NULL, NULL, 0),
(1027, 'insert', '2025-12-01 19:27:44', 'Trigger END', 292, NULL, NULL, NULL, NULL, NULL),
(1028, 'insert', '2025-12-01 19:37:53', 'Trigger START', 293, NULL, 'Programado', NULL, NULL, NULL),
(1029, 'insert', '2025-12-01 19:37:53', 'After Planificacion SELECT', 293, NULL, NULL, 50, NULL, NULL),
(1030, 'insert', '2025-12-01 19:37:53', 'After detalles_planificacion INSERT', 293, 417, 'Programado', NULL, NULL, NULL),
(1031, 'insert', '2025-12-01 19:37:53', 'CONDITION NOT MET for distrib_planif', 293, 417, 'Programado', NULL, NULL, 0),
(1032, 'insert', '2025-12-01 19:37:53', 'Trigger END', 293, NULL, NULL, NULL, NULL, NULL),
(1033, 'insert', '2025-12-01 20:45:14', 'Trigger START', 294, NULL, 'En revisión', NULL, NULL, NULL),
(1034, 'insert', '2025-12-01 20:45:14', 'After Planificacion SELECT', 294, NULL, NULL, 50, NULL, NULL),
(1035, 'insert', '2025-12-01 20:45:14', 'After detalles_planificacion INSERT', 294, 418, 'En revisión', NULL, NULL, NULL),
(1036, 'insert', '2025-12-01 20:45:14', 'CONDITION NOT MET for distrib_planif', 294, 418, 'En revisión', NULL, NULL, 0),
(1037, 'insert', '2025-12-01 20:45:14', 'Trigger END', 294, NULL, NULL, NULL, NULL, NULL),
(1038, 'insert', '2025-12-01 20:45:52', 'Trigger START', 295, NULL, 'En proceso', NULL, NULL, NULL),
(1039, 'insert', '2025-12-01 20:45:52', 'After Planificacion SELECT', 295, NULL, NULL, 50, NULL, NULL),
(1040, 'insert', '2025-12-01 20:45:52', 'After detalles_planificacion INSERT', 295, 419, 'En proceso', NULL, NULL, NULL),
(1041, 'insert', '2025-12-01 20:45:52', 'CONDITION NOT MET for distrib_planif', 295, 419, 'En proceso', NULL, NULL, 0),
(1042, 'insert', '2025-12-01 20:45:52', 'Trigger END', 295, NULL, NULL, NULL, NULL, NULL),
(1043, 'insert', '2025-12-01 20:47:23', 'Trigger START', 296, NULL, 'En proceso', NULL, NULL, NULL),
(1044, 'insert', '2025-12-01 20:47:23', 'After Planificacion SELECT', 296, NULL, NULL, NULL, NULL, NULL),
(1045, 'insert', '2025-12-01 20:47:23', 'v_idplanificacion IS NULL', 296, NULL, NULL, NULL, NULL, 0),
(1046, 'insert', '2025-12-01 20:47:23', 'Trigger END', 296, NULL, NULL, NULL, NULL, NULL),
(1047, 'insert', '2025-12-01 20:48:32', 'Trigger START', 297, NULL, 'En proceso', NULL, NULL, NULL),
(1048, 'insert', '2025-12-01 20:48:32', 'After Planificacion SELECT', 297, NULL, NULL, 51, NULL, NULL),
(1049, 'insert', '2025-12-01 20:48:32', 'After detalles_planificacion INSERT', 297, 420, 'En proceso', NULL, NULL, NULL),
(1050, 'insert', '2025-12-01 20:48:32', 'CONDITION NOT MET for distrib_planif', 297, 420, 'En proceso', NULL, NULL, 0),
(1051, 'insert', '2025-12-01 20:48:32', 'Trigger END', 297, NULL, NULL, NULL, NULL, NULL),
(1052, 'insert', '2025-12-01 20:49:34', 'Trigger START', 298, NULL, 'En proceso', NULL, NULL, NULL),
(1053, 'insert', '2025-12-01 20:49:34', 'After Planificacion SELECT', 298, NULL, NULL, 48, NULL, NULL),
(1054, 'insert', '2025-12-01 20:49:34', 'After detalles_planificacion INSERT', 298, 421, 'En proceso', NULL, NULL, NULL),
(1055, 'insert', '2025-12-01 20:49:34', 'CONDITION NOT MET for distrib_planif', 298, 421, 'En proceso', NULL, NULL, 0),
(1056, 'insert', '2025-12-01 20:49:34', 'Trigger END', 298, NULL, NULL, NULL, NULL, NULL),
(1057, 'insert', '2025-12-01 20:51:10', 'Trigger START', 299, NULL, 'En proceso', NULL, NULL, NULL),
(1058, 'insert', '2025-12-01 20:51:10', 'After Planificacion SELECT', 299, NULL, NULL, 51, NULL, NULL),
(1059, 'insert', '2025-12-01 20:51:10', 'After detalles_planificacion INSERT', 299, 422, 'En proceso', NULL, NULL, NULL),
(1060, 'insert', '2025-12-01 20:51:10', 'CONDITION NOT MET for distrib_planif', 299, 422, 'En proceso', NULL, NULL, 0),
(1061, 'insert', '2025-12-01 20:51:10', 'Trigger END', 299, NULL, NULL, NULL, NULL, NULL),
(1062, 'insert', '2025-12-01 20:52:55', 'Trigger START', 300, NULL, 'En proceso', NULL, NULL, NULL),
(1063, 'insert', '2025-12-01 20:52:55', 'After Planificacion SELECT', 300, NULL, NULL, 51, NULL, NULL),
(1064, 'insert', '2025-12-01 20:52:55', 'After detalles_planificacion INSERT', 300, 423, 'En proceso', NULL, NULL, NULL),
(1065, 'insert', '2025-12-01 20:52:55', 'CONDITION NOT MET for distrib_planif', 300, 423, 'En proceso', NULL, NULL, 0),
(1066, 'insert', '2025-12-01 20:52:55', 'Trigger END', 300, NULL, NULL, NULL, NULL, NULL),
(1067, 'insert', '2025-12-01 20:55:39', 'Trigger START', 301, NULL, 'En proceso', NULL, NULL, NULL),
(1068, 'insert', '2025-12-01 20:55:39', 'After Planificacion SELECT', 301, NULL, NULL, 51, NULL, NULL),
(1069, 'insert', '2025-12-01 20:55:39', 'After detalles_planificacion INSERT', 301, 424, 'En proceso', NULL, NULL, NULL),
(1070, 'insert', '2025-12-01 20:55:39', 'CONDITION NOT MET for distrib_planif', 301, 424, 'En proceso', NULL, NULL, 0),
(1071, 'insert', '2025-12-01 20:55:39', 'Trigger END', 301, NULL, NULL, NULL, NULL, NULL),
(1072, 'insert', '2025-12-02 19:00:06', 'Trigger START', 302, NULL, 'En proceso', NULL, NULL, NULL),
(1073, 'insert', '2025-12-02 19:00:06', 'After Planificacion SELECT', 302, NULL, NULL, 49, NULL, NULL),
(1074, 'insert', '2025-12-02 19:00:06', 'After detalles_planificacion INSERT', 302, 425, 'En proceso', NULL, NULL, NULL),
(1075, 'insert', '2025-12-02 19:00:06', 'CONDITION NOT MET for distrib_planif', 302, 425, 'En proceso', NULL, NULL, 0),
(1076, 'insert', '2025-12-02 19:00:06', 'Trigger END', 302, NULL, NULL, NULL, NULL, NULL),
(1077, 'insert', '2025-12-02 19:01:21', 'Trigger START', 303, NULL, 'En proceso', NULL, NULL, NULL),
(1078, 'insert', '2025-12-02 19:01:21', 'After Planificacion SELECT', 303, NULL, NULL, 55, NULL, NULL),
(1079, 'insert', '2025-12-02 19:01:21', 'After detalles_planificacion INSERT', 303, 426, 'En proceso', NULL, NULL, NULL),
(1080, 'insert', '2025-12-02 19:01:21', 'CONDITION NOT MET for distrib_planif', 303, 426, 'En proceso', NULL, NULL, 0),
(1081, 'insert', '2025-12-02 19:01:21', 'Trigger END', 303, NULL, NULL, NULL, NULL, NULL),
(1082, 'insert', '2025-12-04 16:28:02', 'Trigger START', 304, NULL, 'En proceso', NULL, NULL, NULL),
(1083, 'insert', '2025-12-04 16:28:02', 'After Planificacion SELECT', 304, NULL, NULL, 53, NULL, NULL),
(1084, 'insert', '2025-12-04 16:28:02', 'After detalles_planificacion INSERT', 304, 427, 'En proceso', NULL, NULL, NULL),
(1085, 'insert', '2025-12-04 16:28:02', 'CONDITION NOT MET for distrib_planif', 304, 427, 'En proceso', NULL, NULL, 0),
(1086, 'insert', '2025-12-04 16:28:02', 'Trigger END', 304, NULL, NULL, NULL, NULL, NULL),
(1087, 'insert', '2025-12-04 17:04:48', 'Trigger START', 305, NULL, 'Completo', NULL, NULL, NULL),
(1088, 'insert', '2025-12-04 17:04:48', 'After Planificacion SELECT', 305, NULL, NULL, 48, NULL, NULL),
(1089, 'insert', '2025-12-04 17:04:48', 'After detalles_planificacion INSERT', 305, 428, 'Completo', NULL, NULL, NULL),
(1090, 'insert', '2025-12-04 17:04:48', 'CONDITION MET for distrib_planif', 305, 428, 'Completo', NULL, NULL, 0),
(1091, 'insert', '2025-12-04 17:04:48', 'Count from distribucionhora', 305, NULL, NULL, NULL, 0, NULL),
(1092, 'insert', '2025-12-04 17:04:48', 'Skipped INSERT (no rows in distribucionhora)', 305, NULL, NULL, NULL, 0, 0),
(1093, 'insert', '2025-12-04 17:04:48', 'Trigger END', 305, NULL, NULL, NULL, NULL, NULL),
(1094, 'insert', '2025-12-04 17:21:19', 'Trigger START', 306, NULL, 'Completo', NULL, NULL, NULL),
(1095, 'insert', '2025-12-04 17:21:19', 'After Planificacion SELECT', 306, NULL, NULL, 55, NULL, NULL),
(1096, 'insert', '2025-12-04 17:21:19', 'After detalles_planificacion INSERT', 306, 429, 'Completo', NULL, NULL, NULL),
(1097, 'insert', '2025-12-04 17:21:19', 'CONDITION MET for distrib_planif', 306, 429, 'Completo', NULL, NULL, 0),
(1098, 'insert', '2025-12-04 17:21:19', 'Count from distribucionhora', 306, NULL, NULL, NULL, 0, NULL),
(1099, 'insert', '2025-12-04 17:21:19', 'Skipped INSERT (no rows in distribucionhora)', 306, NULL, NULL, NULL, 0, 0),
(1100, 'insert', '2025-12-04 17:21:19', 'Trigger END', 306, NULL, NULL, NULL, NULL, NULL),
(1101, 'insert', '2025-12-04 17:31:26', 'Trigger START', 307, NULL, 'Completo', NULL, NULL, NULL),
(1102, 'insert', '2025-12-04 17:31:26', 'After Planificacion SELECT', 307, NULL, NULL, 52, NULL, NULL),
(1103, 'insert', '2025-12-04 17:31:26', 'After detalles_planificacion INSERT', 307, 430, 'Completo', NULL, NULL, NULL),
(1104, 'insert', '2025-12-04 17:31:26', 'CONDITION MET for distrib_planif', 307, 430, 'Completo', NULL, NULL, 0),
(1105, 'insert', '2025-12-04 17:31:26', 'Count from distribucionhora', 307, NULL, NULL, NULL, 0, NULL),
(1106, 'insert', '2025-12-04 17:31:26', 'Skipped INSERT (no rows in distribucionhora)', 307, NULL, NULL, NULL, 0, 0),
(1107, 'insert', '2025-12-04 17:31:26', 'Trigger END', 307, NULL, NULL, NULL, NULL, NULL),
(1108, 'insert', '2025-12-04 17:37:22', 'Trigger START', 308, NULL, 'Completo', NULL, NULL, NULL),
(1109, 'insert', '2025-12-04 17:37:22', 'After Planificacion SELECT', 308, NULL, NULL, 55, NULL, NULL),
(1110, 'insert', '2025-12-04 17:37:22', 'After detalles_planificacion INSERT', 308, 431, 'Completo', NULL, NULL, NULL),
(1111, 'insert', '2025-12-04 17:37:22', 'CONDITION MET for distrib_planif', 308, 431, 'Completo', NULL, NULL, 0),
(1112, 'insert', '2025-12-04 17:37:22', 'Count from distribucionhora', 308, NULL, NULL, NULL, 0, NULL),
(1113, 'insert', '2025-12-04 17:37:22', 'Skipped INSERT (no rows in distribucionhora)', 308, NULL, NULL, NULL, 0, 0),
(1114, 'insert', '2025-12-04 17:37:22', 'Trigger END', 308, NULL, NULL, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuario`
--

CREATE TABLE `usuario` (
  `idusuario` int(11) NOT NULL,
  `nombre` varchar(50) NOT NULL,
  `password` varchar(250) NOT NULL,
  `tipo` int(11) NOT NULL,
  `activo` int(11) NOT NULL,
  `idemp` int(11) DEFAULT NULL,
  `editor` int(11) NOT NULL DEFAULT 1,
  `registrado` timestamp NOT NULL DEFAULT current_timestamp(),
  `modificado` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `usuario`
--

INSERT INTO `usuario` (`idusuario`, `nombre`, `password`, `tipo`, `activo`, `idemp`, `editor`, `registrado`, `modificado`) VALUES
(1, 'jcornejo', '$2y$10$jQsgtP.Ob.dpNMrOV40.N.r5na./hHzbolcBvQRxH114.ST/SCoAG', 1, 1, 8, 1, '2025-07-07 13:20:05', '2025-07-07 13:20:05'),
(2, 'gkou', '$2y$10$PBwbumenp2mP.AuzpWO6sell2NaeX2X17FODMEjk01tTlz/p4Vdre', 1, 1, 9, 1, '2025-07-07 13:20:05', '2025-07-07 13:20:05'),
(3, 'mgonzalez', '$2y$10$JvKZ7J7PMf5chD1TebcIJe4GU4AB33lgSXTC/VcDVFiGQdigNrN3S', 1, 1, 2, 1, '2025-07-07 13:20:05', '2025-07-07 13:20:05'),
(4, 'jrojas', '$2y$10$Dbe0gj5oCAqOjyqnaSRfQuL7RX/7CNqq73C9PX0EBnNqRHCG.HidO', 2, 1, 3, 2, '2025-07-07 13:20:05', '2025-07-08 16:16:22'),
(5, 'gramirez', '$2y$10$dlVD3Aiu4y4HiqzPA38gHuowS6.5EORjOheh7rDRTFXiVmeMkY3o6', 2, 1, 4, 1, '2025-07-07 13:20:05', '2025-07-07 13:20:05'),
(6, 'jtorres', '$2y$10$bSCVJ.yBZdtBdHEfI0.yBe1a0XUaRPywYnDcqt10GT1NVPxhrSroW', 2, 0, 6, 2, '2025-07-07 13:20:05', '2025-09-08 16:00:04'),
(7, 'knieto', '$2y$10$dw8MwCohjxqX09eUpbA99OFOOOzAEPLNRUmiYVxIojV.QglIWd.NG', 3, 0, 5, 2, '2025-07-07 13:20:05', '2025-08-15 18:11:43'),
(8, 'hore', '$2y$10$Os1dhPTUXrBMfKqFR1MhO.iWIr/Oi.n3gicEySddvwoYEPDt/6cMi', 1, 1, 11, 2, '2025-07-23 00:04:46', '2025-11-28 10:32:43'),
(9, 'pconde', '$2y$10$BJl5xrLzuRJ0F5SVoZmPjOGKLr0bMoKtXSIRmQJz9VT5lBfEZ3e1G', 2, 1, 12, 2, '2025-10-06 17:06:42', '2025-10-06 17:06:42'),
(10, 'ecastro', '$2y$10$WLntYJo6ljvHPhZf3Aab.e5rQfimihCRyTdI4PUxDECSXwntQnUU2', 2, 1, 13, 2, '2025-10-13 14:47:53', '2025-10-13 14:47:53');

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_contratocliente_activo`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_contratocliente_activo` (
`idcontratocli` int(11)
,`idcliente` int(11)
,`lider` int(11)
,`descripcion` varchar(500)
,`fechainicio` date
,`fechafin` date
,`horasfijasmes` int(11)
,`costohorafija` decimal(7,2)
,`mesescontrato` int(11)
,`totalhorasfijas` int(11)
,`tipobolsa` varchar(50)
,`costohoraextra` decimal(7,2)
,`montofijomes` decimal(7,2)
,`planmontomes` decimal(7,2)
,`planhoraextrames` int(11)
,`status` varchar(50)
,`tipohora` varchar(500)
,`activo` int(11)
,`editor` int(11)
,`registrado` timestamp
,`modificado` timestamp
,`ultima_adenda_id` int(11)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_planificacion_vs_participantes_completado`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_planificacion_vs_participantes_completado` (
`Idplanificacion` int(11)
,`NombrePlan` varchar(255)
,`MesPlan` varchar(7)
,`idContratoCliente` int(11)
,`NombreCliente` varchar(50)
,`HorasPlanificadasGlobal` int(11)
,`TotalHorasLiquidadasCompletadas` decimal(32,0)
,`PorcentajePlanCompletado` decimal(40,5)
,`IdParticipante` int(11)
,`NombreParticipante` varchar(50)
,`HorasCompletadasPorParticipante` decimal(32,2)
,`PorcentajeDelParticipanteEnCompletadas` decimal(40,7)
,`PorcentajeDelParticipanteEnPlanGlobal` decimal(40,7)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_progreso_colaborador_vs_meta`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_progreso_colaborador_vs_meta` (
`idempleado` int(11)
,`NombreColaborador` varchar(50)
,`HorasMeta` int(11)
,`Anio` int(4)
,`Mes` int(2)
,`HorasCompletadas` decimal(32,2)
,`PorcentajeCumplimiento` decimal(39,6)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_reporte_planificacion_vs_liquidacion`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_reporte_planificacion_vs_liquidacion` (
`Idplanificacion` int(11)
,`NombrePlan` varchar(255)
,`MesPlan` varchar(7)
,`AnioPlan` int(4)
,`MesPlanNumerico` int(2)
,`idContratoCliente` int(11)
,`NombreCliente` varchar(50)
,`HorasPlanificadas` int(11)
,`EstadoLiquidacion` varchar(50)
,`HorasLiquidadasPorEstado` decimal(32,0)
,`TotalHorasLiquidadasMes` decimal(32,0)
,`PorcentajeConsumidoPorEstado` decimal(40,5)
,`PorcentajeTotalConsumidoMes` decimal(40,5)
);

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_contratocliente_activo`
--
DROP TABLE IF EXISTS `vista_contratocliente_activo`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`127.0.0.1` SQL SECURITY DEFINER VIEW `vista_contratocliente_activo`  AS WITH UltimaAdenda AS (SELECT `ac`.`idcontratocli` AS `idcontratocli`, `ac`.`idadendacli` AS `idadendacli`, `ac`.`fechainicio` AS `fechainicio`, `ac`.`fechafin` AS `fechafin`, `ac`.`horasfijasmes` AS `horasfijasmes`, `ac`.`costohorafija` AS `costohorafija`, `ac`.`mesescontrato` AS `mesescontrato`, `ac`.`totalhorasfijas` AS `totalhorasfijas`, `ac`.`tipobolsa` AS `tipobolsa`, `ac`.`costohoraextra` AS `costohoraextra`, `ac`.`montofijomes` AS `montofijomes`, `ac`.`planmontomes` AS `planmontomes`, `ac`.`planhorasextrasmes` AS `planhorasextrasmes`, row_number() over ( partition by `ac`.`idcontratocli` order by `ac`.`fechainicio` desc,`ac`.`registrado` desc) AS `rn` FROM `adendacliente` AS `ac`)  SELECT `cc`.`idcontratocli` AS `idcontratocli`, `cc`.`idcliente` AS `idcliente`, `cc`.`lider` AS `lider`, `cc`.`descripcion` AS `descripcion`, coalesce(`ua`.`fechainicio`,`cc`.`fechainicio`) AS `fechainicio`, coalesce(`ua`.`fechafin`,`cc`.`fechafin`) AS `fechafin`, coalesce(`ua`.`horasfijasmes`,`cc`.`horasfijasmes`) AS `horasfijasmes`, coalesce(`ua`.`costohorafija`,`cc`.`costohorafija`) AS `costohorafija`, coalesce(`ua`.`mesescontrato`,`cc`.`mesescontrato`) AS `mesescontrato`, coalesce(`ua`.`totalhorasfijas`,`cc`.`totalhorasfijas`) AS `totalhorasfijas`, coalesce(`ua`.`tipobolsa`,`cc`.`tipobolsa`) AS `tipobolsa`, coalesce(`ua`.`costohoraextra`,`cc`.`costohoraextra`) AS `costohoraextra`, coalesce(`ua`.`montofijomes`,`cc`.`montofijomes`) AS `montofijomes`, coalesce(`ua`.`planmontomes`,`cc`.`planmontomes`) AS `planmontomes`, coalesce(`ua`.`planhorasextrasmes`,`cc`.`planhoraextrames`) AS `planhoraextrames`, `cc`.`status` AS `status`, `cc`.`tipohora` AS `tipohora`, `cc`.`activo` AS `activo`, `cc`.`editor` AS `editor`, `cc`.`registrado` AS `registrado`, `cc`.`modificado` AS `modificado`, `ua`.`idadendacli` AS `ultima_adenda_id` FROM (`contratocliente` `cc` left join `ultimaadenda` `ua` on(`cc`.`idcontratocli` = `ua`.`idcontratocli` and `ua`.`rn` = 1))  ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_planificacion_vs_participantes_completado`
--
DROP TABLE IF EXISTS `vista_planificacion_vs_participantes_completado`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`127.0.0.1` SQL SECURITY DEFINER VIEW `vista_planificacion_vs_participantes_completado`  AS WITH PlanificacionHorasCompletadas AS (SELECT `p`.`Idplanificacion` AS `Idplanificacion`, `p`.`nombreplan` AS `nombreplan`, `p`.`fechaplan` AS `fechaplan`, `p`.`idContratoCliente` AS `idContratoCliente`, `p`.`horasplan` AS `HorasPlanificadasGlobal`, sum(case when `dp`.`estado` = 'Completo' then `dp`.`cantidahoras` else 0 end) AS `TotalHorasLiquidadasCompletadas` FROM (`planificacion` `p` left join `detalles_planificacion` `dp` on(`p`.`Idplanificacion` = `dp`.`Idplanificacion`)) GROUP BY `p`.`Idplanificacion`, `p`.`nombreplan`, `p`.`fechaplan`, `p`.`idContratoCliente`, `p`.`horasplan`), HorasCompletadasPorParticipante AS (SELECT `dp`.`Idplanificacion` AS `Idplanificacion`, `dplan`.`idparticipante` AS `idparticipante`, sum(`dplan`.`horas_asignadas`) AS `HorasAsignadasAlParticipante` FROM (`detalles_planificacion` `dp` join `distribucion_planificacion` `dplan` on(`dp`.`iddetalle` = `dplan`.`iddetalle`)) WHERE `dp`.`estado` = 'Completo' GROUP BY `dp`.`Idplanificacion`, `dplan`.`idparticipante`)  SELECT `phc`.`Idplanificacion` AS `Idplanificacion`, `phc`.`nombreplan` AS `NombrePlan`, date_format(`phc`.`fechaplan`,'%Y-%m') AS `MesPlan`, `phc`.`idContratoCliente` AS `idContratoCliente`, `cli`.`nombrecomercial` AS `NombreCliente`, `phc`.`HorasPlanificadasGlobal` AS `HorasPlanificadasGlobal`, coalesce(`phc`.`TotalHorasLiquidadasCompletadas`,0) AS `TotalHorasLiquidadasCompletadas`, CASE WHEN `phc`.`HorasPlanificadasGlobal` is null OR `phc`.`HorasPlanificadasGlobal` = 0 THEN 0 ELSE coalesce(`phc`.`TotalHorasLiquidadasCompletadas`,0) * 100.0 / `phc`.`HorasPlanificadasGlobal` END AS `PorcentajePlanCompletado`, `hpp`.`idparticipante` AS `IdParticipante`, `emp`.`nombrecorto` AS `NombreParticipante`, coalesce(`hpp`.`HorasAsignadasAlParticipante`,0) AS `HorasCompletadasPorParticipante`, CASE WHEN coalesce(`phc`.`TotalHorasLiquidadasCompletadas`,0) = 0 THEN 0 ELSE coalesce(`hpp`.`HorasAsignadasAlParticipante`,0) * 100.0 / `phc`.`TotalHorasLiquidadasCompletadas` END AS `PorcentajeDelParticipanteEnCompletadas`, CASE WHEN `phc`.`HorasPlanificadasGlobal` is null OR `phc`.`HorasPlanificadasGlobal` = 0 THEN 0 ELSE coalesce(`hpp`.`HorasAsignadasAlParticipante`,0) * 100.0 / `phc`.`HorasPlanificadasGlobal` END AS `PorcentajeDelParticipanteEnPlanGlobal` FROM ((((`planificacionhorascompletadas` `phc` left join `horascompletadasporparticipante` `hpp` on(`phc`.`Idplanificacion` = `hpp`.`Idplanificacion`)) left join `empleado` `emp` on(`hpp`.`idparticipante` = `emp`.`idempleado`)) left join `contratocliente` `cc` on(`phc`.`idContratoCliente` = `cc`.`idcontratocli`)) left join `cliente` `cli` on(`cc`.`idcliente` = `cli`.`idcliente`)) ORDER BY date_format(`phc`.`fechaplan`,'%Y-%m') DESC, `phc`.`Idplanificacion` ASC, `emp`.`nombrecorto` ASC;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_progreso_colaborador_vs_meta`
--
DROP TABLE IF EXISTS `vista_progreso_colaborador_vs_meta`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`127.0.0.1` SQL SECURITY DEFINER VIEW `vista_progreso_colaborador_vs_meta`  AS SELECT `e`.`idempleado` AS `idempleado`, `e`.`nombrecorto` AS `NombreColaborador`, `e`.`horasmeta` AS `HorasMeta`, year(`l`.`fecha`) AS `Anio`, month(`l`.`fecha`) AS `Mes`, sum(`dh`.`calculo`) AS `HorasCompletadas`, sum(`dh`.`calculo`) / `e`.`horasmeta` * 100 AS `PorcentajeCumplimiento` FROM ((`distribucionhora` `dh` join `liquidacion` `l` on(`dh`.`idliquidacion` = `l`.`idliquidacion`)) join `empleado` `e` on(`dh`.`participante` = `e`.`idempleado`)) WHERE `l`.`estado` = 'Completo' GROUP BY `e`.`idempleado`, `e`.`nombrecorto`, `e`.`horasmeta`, year(`l`.`fecha`), month(`l`.`fecha`) ORDER BY year(`l`.`fecha`) DESC, month(`l`.`fecha`) DESC, `e`.`nombrecorto` ASC ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_reporte_planificacion_vs_liquidacion`
--
DROP TABLE IF EXISTS `vista_reporte_planificacion_vs_liquidacion`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`127.0.0.1` SQL SECURITY DEFINER VIEW `vista_reporte_planificacion_vs_liquidacion`  AS WITH PlanificacionConTotalesLiquidadas AS (SELECT `p`.`Idplanificacion` AS `Idplanificacion`, `p`.`nombreplan` AS `nombreplan`, `p`.`fechaplan` AS `fechaplan`, `p`.`idContratoCliente` AS `idContratoCliente`, `p`.`horasplan` AS `horasplan`, sum(`dp`.`cantidahoras`) AS `TotalHorasLiquidadasMes` FROM (`planificacion` `p` left join `detalles_planificacion` `dp` on(`p`.`Idplanificacion` = `dp`.`Idplanificacion`)) GROUP BY `p`.`Idplanificacion`, `p`.`nombreplan`, `p`.`fechaplan`, `p`.`idContratoCliente`, `p`.`horasplan`), PlanificacionDetallePorEstado AS (SELECT `p`.`Idplanificacion` AS `Idplanificacion`, `dp`.`estado` AS `EstadoLiquidacion`, sum(`dp`.`cantidahoras`) AS `HorasLiquidadasPorEstado` FROM (`planificacion` `p` join `detalles_planificacion` `dp` on(`p`.`Idplanificacion` = `dp`.`Idplanificacion`)) GROUP BY `p`.`Idplanificacion`, `dp`.`estado`)  SELECT `ptl`.`Idplanificacion` AS `Idplanificacion`, `ptl`.`nombreplan` AS `NombrePlan`, date_format(`ptl`.`fechaplan`,'%Y-%m') AS `MesPlan`, year(`ptl`.`fechaplan`) AS `AnioPlan`, month(`ptl`.`fechaplan`) AS `MesPlanNumerico`, `ptl`.`idContratoCliente` AS `idContratoCliente`, `cli`.`nombrecomercial` AS `NombreCliente`, `ptl`.`horasplan` AS `HorasPlanificadas`, coalesce(`pdpe`.`EstadoLiquidacion`,'Sin Liquidaciones') AS `EstadoLiquidacion`, coalesce(`pdpe`.`HorasLiquidadasPorEstado`,0) AS `HorasLiquidadasPorEstado`, coalesce(`ptl`.`TotalHorasLiquidadasMes`,0) AS `TotalHorasLiquidadasMes`, CASE WHEN `ptl`.`horasplan` is null OR `ptl`.`horasplan` = 0 THEN 0 ELSE coalesce(`pdpe`.`HorasLiquidadasPorEstado`,0) * 100.0 / `ptl`.`horasplan` END AS `PorcentajeConsumidoPorEstado`, CASE WHEN `ptl`.`horasplan` is null OR `ptl`.`horasplan` = 0 THEN 0 ELSE coalesce(`ptl`.`TotalHorasLiquidadasMes`,0) * 100.0 / `ptl`.`horasplan` END AS `PorcentajeTotalConsumidoMes` FROM (((`planificacioncontotalesliquidadas` `ptl` left join `planificaciondetalleporestado` `pdpe` on(`ptl`.`Idplanificacion` = `pdpe`.`Idplanificacion`)) left join `contratocliente` `cc` on(`ptl`.`idContratoCliente` = `cc`.`idcontratocli`)) left join `cliente` `cli` on(`cc`.`idcliente` = `cli`.`idcliente`)) ;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `adendacliente`
--
ALTER TABLE `adendacliente`
  ADD PRIMARY KEY (`idadendacli`),
  ADD KEY `idcontratocli` (`idcontratocli`);

--
-- Indices de la tabla `adendaempleado`
--
ALTER TABLE `adendaempleado`
  ADD PRIMARY KEY (`idadendaemp`),
  ADD KEY `idcontratoemp` (`idcontratoemp`);

--
-- Indices de la tabla `alerta_normativa`
--
ALTER TABLE `alerta_normativa`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `anuncio`
--
ALTER TABLE `anuncio`
  ADD PRIMARY KEY (`idanuncio`),
  ADD KEY `acargode` (`editor`);

--
-- Indices de la tabla `boletin_regulatorio`
--
ALTER TABLE `boletin_regulatorio`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `calendario`
--
ALTER TABLE `calendario`
  ADD PRIMARY KEY (`idcalendario`),
  ADD KEY `acargode` (`acargode`);

--
-- Indices de la tabla `cliente`
--
ALTER TABLE `cliente`
  ADD PRIMARY KEY (`idcliente`);

--
-- Indices de la tabla `contratocliente`
--
ALTER TABLE `contratocliente`
  ADD PRIMARY KEY (`idcontratocli`),
  ADD KEY `idcliente` (`idcliente`),
  ADD KEY `lider` (`lider`);

--
-- Indices de la tabla `contratoempleado`
--
ALTER TABLE `contratoempleado`
  ADD PRIMARY KEY (`idcontratoemp`),
  ADD KEY `idemp` (`idemp`);

--
-- Indices de la tabla `cuotahito`
--
ALTER TABLE `cuotahito`
  ADD PRIMARY KEY (`idcouta`),
  ADD KEY `idpresupuesto` (`idpresupuesto`);

--
-- Indices de la tabla `detalle`
--
ALTER TABLE `detalle`
  ADD KEY `idfacturacion` (`idfacturacion`);

--
-- Indices de la tabla `detalles_planificacion`
--
ALTER TABLE `detalles_planificacion`
  ADD PRIMARY KEY (`iddetalle`),
  ADD KEY `idx_Idplanificacion` (`Idplanificacion`),
  ADD KEY `idx_idliquidacion` (`idliquidacion`);

--
-- Indices de la tabla `distribucionhora`
--
ALTER TABLE `distribucionhora`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idliquidacion` (`idliquidacion`);

--
-- Indices de la tabla `distribucion_planificacion`
--
ALTER TABLE `distribucion_planificacion`
  ADD PRIMARY KEY (`iddistribucionplan`),
  ADD KEY `idx_iddetalle` (`iddetalle`),
  ADD KEY `idx_idparticipante` (`idparticipante`);

--
-- Indices de la tabla `empleado`
--
ALTER TABLE `empleado`
  ADD PRIMARY KEY (`idempleado`);

--
-- Indices de la tabla `evento`
--
ALTER TABLE `evento`
  ADD PRIMARY KEY (`idevento`),
  ADD KEY `acargode` (`acargode`);

--
-- Indices de la tabla `facturacion`
--
ALTER TABLE `facturacion`
  ADD PRIMARY KEY (`idfacturacion`),
  ADD KEY `idcliente` (`idcliente`);

--
-- Indices de la tabla `liquidacion`
--
ALTER TABLE `liquidacion`
  ADD PRIMARY KEY (`idliquidacion`),
  ADD KEY `idcontratocli` (`idcontratocli`),
  ADD KEY `tema` (`tema`),
  ADD KEY `acargode` (`acargode`);

--
-- Indices de la tabla `planificacion`
--
ALTER TABLE `planificacion`
  ADD PRIMARY KEY (`Idplanificacion`),
  ADD KEY `idx_idContratoCliente` (`idContratoCliente`),
  ADD KEY `idx_lider` (`lider`),
  ADD KEY `idx_editor` (`editor`);

--
-- Indices de la tabla `presupuestocliente`
--
ALTER TABLE `presupuestocliente`
  ADD PRIMARY KEY (`idpresupuesto`),
  ADD KEY `idcliente` (`idcliente`),
  ADD KEY `acargode` (`acargode`);

--
-- Indices de la tabla `sesiones_log`
--
ALTER TABLE `sesiones_log`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `tema`
--
ALTER TABLE `tema`
  ADD PRIMARY KEY (`idtema`);

--
-- Indices de la tabla `trigger_debug_log`
--
ALTER TABLE `trigger_debug_log`
  ADD PRIMARY KEY (`log_id`);

--
-- Indices de la tabla `usuario`
--
ALTER TABLE `usuario`
  ADD PRIMARY KEY (`idusuario`),
  ADD KEY `idemp` (`idemp`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `adendacliente`
--
ALTER TABLE `adendacliente`
  MODIFY `idadendacli` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT de la tabla `adendaempleado`
--
ALTER TABLE `adendaempleado`
  MODIFY `idadendaemp` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `alerta_normativa`
--
ALTER TABLE `alerta_normativa`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `anuncio`
--
ALTER TABLE `anuncio`
  MODIFY `idanuncio` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT de la tabla `boletin_regulatorio`
--
ALTER TABLE `boletin_regulatorio`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `calendario`
--
ALTER TABLE `calendario`
  MODIFY `idcalendario` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `cliente`
--
ALTER TABLE `cliente`
  MODIFY `idcliente` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT de la tabla `contratocliente`
--
ALTER TABLE `contratocliente`
  MODIFY `idcontratocli` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT de la tabla `contratoempleado`
--
ALTER TABLE `contratoempleado`
  MODIFY `idcontratoemp` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT de la tabla `cuotahito`
--
ALTER TABLE `cuotahito`
  MODIFY `idcouta` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `detalles_planificacion`
--
ALTER TABLE `detalles_planificacion`
  MODIFY `iddetalle` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=432;

--
-- AUTO_INCREMENT de la tabla `distribucionhora`
--
ALTER TABLE `distribucionhora`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=851;

--
-- AUTO_INCREMENT de la tabla `distribucion_planificacion`
--
ALTER TABLE `distribucion_planificacion`
  MODIFY `iddistribucionplan` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4706;

--
-- AUTO_INCREMENT de la tabla `empleado`
--
ALTER TABLE `empleado`
  MODIFY `idempleado` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT de la tabla `evento`
--
ALTER TABLE `evento`
  MODIFY `idevento` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `facturacion`
--
ALTER TABLE `facturacion`
  MODIFY `idfacturacion` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `liquidacion`
--
ALTER TABLE `liquidacion`
  MODIFY `idliquidacion` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=309;

--
-- AUTO_INCREMENT de la tabla `planificacion`
--
ALTER TABLE `planificacion`
  MODIFY `Idplanificacion` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=56;

--
-- AUTO_INCREMENT de la tabla `presupuestocliente`
--
ALTER TABLE `presupuestocliente`
  MODIFY `idpresupuesto` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `sesiones_log`
--
ALTER TABLE `sesiones_log`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=389;

--
-- AUTO_INCREMENT de la tabla `tema`
--
ALTER TABLE `tema`
  MODIFY `idtema` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=39;

--
-- AUTO_INCREMENT de la tabla `trigger_debug_log`
--
ALTER TABLE `trigger_debug_log`
  MODIFY `log_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1115;

--
-- AUTO_INCREMENT de la tabla `usuario`
--
ALTER TABLE `usuario`
  MODIFY `idusuario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `adendacliente`
--
ALTER TABLE `adendacliente`
  ADD CONSTRAINT `adendacliente_ibfk_1` FOREIGN KEY (`idcontratocli`) REFERENCES `contratocliente` (`idcontratocli`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Filtros para la tabla `adendaempleado`
--
ALTER TABLE `adendaempleado`
  ADD CONSTRAINT `adendaempleado_ibfk_1` FOREIGN KEY (`idadendaemp`) REFERENCES `contratoempleado` (`idcontratoemp`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Filtros para la tabla `anuncio`
--
ALTER TABLE `anuncio`
  ADD CONSTRAINT `anuncio_ibfk_1` FOREIGN KEY (`editor`) REFERENCES `empleado` (`idempleado`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Filtros para la tabla `calendario`
--
ALTER TABLE `calendario`
  ADD CONSTRAINT `calendario_ibfk_1` FOREIGN KEY (`acargode`) REFERENCES `empleado` (`idempleado`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Filtros para la tabla `contratocliente`
--
ALTER TABLE `contratocliente`
  ADD CONSTRAINT `contratocliente_ibfk_1` FOREIGN KEY (`idcliente`) REFERENCES `cliente` (`idcliente`) ON DELETE NO ACTION ON UPDATE CASCADE,
  ADD CONSTRAINT `contratocliente_ibfk_2` FOREIGN KEY (`lider`) REFERENCES `empleado` (`idempleado`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Filtros para la tabla `contratoempleado`
--
ALTER TABLE `contratoempleado`
  ADD CONSTRAINT `contratoempleado_ibfk_1` FOREIGN KEY (`idemp`) REFERENCES `empleado` (`idempleado`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Filtros para la tabla `cuotahito`
--
ALTER TABLE `cuotahito`
  ADD CONSTRAINT `cuotahito_ibfk_1` FOREIGN KEY (`idpresupuesto`) REFERENCES `presupuestocliente` (`idpresupuesto`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Filtros para la tabla `detalle`
--
ALTER TABLE `detalle`
  ADD CONSTRAINT `detalle_ibfk_1` FOREIGN KEY (`idfacturacion`) REFERENCES `facturacion` (`idfacturacion`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Filtros para la tabla `detalles_planificacion`
--
ALTER TABLE `detalles_planificacion`
  ADD CONSTRAINT `fk_detalles_planificacion_liquidacion` FOREIGN KEY (`idliquidacion`) REFERENCES `liquidacion` (`idliquidacion`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_detalles_planificacion_planificacion` FOREIGN KEY (`Idplanificacion`) REFERENCES `planificacion` (`Idplanificacion`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `distribucionhora`
--
ALTER TABLE `distribucionhora`
  ADD CONSTRAINT `distribucionhora_ibfk_1` FOREIGN KEY (`idliquidacion`) REFERENCES `liquidacion` (`idliquidacion`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Filtros para la tabla `distribucion_planificacion`
--
ALTER TABLE `distribucion_planificacion`
  ADD CONSTRAINT `fk_distribucion_planificacion_detalles` FOREIGN KEY (`iddetalle`) REFERENCES `detalles_planificacion` (`iddetalle`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_distribucion_planificacion_empleado` FOREIGN KEY (`idparticipante`) REFERENCES `empleado` (`idempleado`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Filtros para la tabla `evento`
--
ALTER TABLE `evento`
  ADD CONSTRAINT `evento_ibfk_1` FOREIGN KEY (`acargode`) REFERENCES `empleado` (`idempleado`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Filtros para la tabla `facturacion`
--
ALTER TABLE `facturacion`
  ADD CONSTRAINT `facturacion_ibfk_1` FOREIGN KEY (`idcliente`) REFERENCES `cliente` (`idcliente`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Filtros para la tabla `liquidacion`
--
ALTER TABLE `liquidacion`
  ADD CONSTRAINT `liquidacion_ibfk_1` FOREIGN KEY (`idcontratocli`) REFERENCES `contratocliente` (`idcontratocli`) ON DELETE NO ACTION ON UPDATE CASCADE,
  ADD CONSTRAINT `liquidacion_ibfk_2` FOREIGN KEY (`tema`) REFERENCES `tema` (`idtema`) ON DELETE NO ACTION ON UPDATE CASCADE,
  ADD CONSTRAINT `liquidacion_ibfk_3` FOREIGN KEY (`acargode`) REFERENCES `empleado` (`idempleado`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Filtros para la tabla `planificacion`
--
ALTER TABLE `planificacion`
  ADD CONSTRAINT `fk_planificacion_contratocliente` FOREIGN KEY (`idContratoCliente`) REFERENCES `contratocliente` (`idcontratocli`) ON DELETE NO ACTION ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_planificacion_editor` FOREIGN KEY (`editor`) REFERENCES `empleado` (`idempleado`) ON DELETE NO ACTION ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_planificacion_lider` FOREIGN KEY (`lider`) REFERENCES `empleado` (`idempleado`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Filtros para la tabla `presupuestocliente`
--
ALTER TABLE `presupuestocliente`
  ADD CONSTRAINT `presupuestocliente_ibfk_1` FOREIGN KEY (`idcliente`) REFERENCES `cliente` (`idcliente`) ON DELETE NO ACTION ON UPDATE CASCADE,
  ADD CONSTRAINT `presupuestocliente_ibfk_2` FOREIGN KEY (`acargode`) REFERENCES `empleado` (`idempleado`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Filtros para la tabla `usuario`
--
ALTER TABLE `usuario`
  ADD CONSTRAINT `usuario_ibfk_1` FOREIGN KEY (`idemp`) REFERENCES `empleado` (`idempleado`) ON DELETE NO ACTION ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
