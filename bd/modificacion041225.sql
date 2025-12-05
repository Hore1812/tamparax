-- =================================================================
-- SCRIPT COMPLETO DE MODIFICACIÓN DE BASE DE DATOS (VERSIÓN FINAL Y COMPLETA)
-- =================================================================

--
-- PASO 1: AÑADIR LAS COLUMNAS FALTANTES A LA TABLA `adendacliente`
--
-- Descripción: Este comando añade todas las columnas nuevas necesarias para que
-- una adenda pueda sobreescribir los valores del contrato principal.
--
ALTER TABLE `adendacliente`
    ADD COLUMN `costohorafija` decimal(7,2) DEFAULT NULL,
    ADD COLUMN `mesescontrato` int(11) DEFAULT NULL,
    ADD COLUMN `totalhorasfijas` int(11) DEFAULT NULL,
    ADD COLUMN `tipobolsa` varchar(50) DEFAULT NULL,
    ADD COLUMN `costohoraextra` decimal(7,2) DEFAULT NULL,
    ADD COLUMN `montofijomes` decimal(7,2) DEFAULT NULL,
    ADD COLUMN `planmontomes` decimal(7,2) DEFAULT NULL,
    ADD COLUMN `planhorasextrasmes` int(11) DEFAULT NULL,
    ADD COLUMN `rutaarchivo` varchar(500) DEFAULT NULL,
    ADD COLUMN `editor` int(11) NOT NULL,
    ADD COLUMN `registrado` timestamp NOT NULL DEFAULT current_timestamp(),
    ADD COLUMN `modificado` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp();

--
-- PASO 2: MODIFICAR LAS COLUMNAS ORIGINALES PARA PERMITIR VALORES NULOS
--
-- Descripción: Se ajustan las columnas que ya existían para que acepten
-- valores nulos, permitiendo que las adendas solo modifiquen campos específicos.
--
ALTER TABLE `adendacliente`
    MODIFY `horasfijasmes` int(11) DEFAULT NULL,
    MODIFY `horasmaxbolsa` int(11) DEFAULT NULL,
    MODIFY `planhorasfijas` int(11) DEFAULT NULL,
    MODIFY `comentarios` varchar(500) DEFAULT NULL;

--
-- PASO 3: ELIMINAR LOS TRIGGERS OBSOLETOS
--
-- Descripción: Se eliminan los triggers que ya no son necesarios.
-- Es seguro ejecutar esto incluso si no existen en tu base de datos.
--
DROP TRIGGER IF EXISTS `trg_after_adendacliente_insert`;
DROP TRIGGER IF EXISTS `trg_after_adendacliente_update`;

--
-- PASO 4: CREAR LA VISTA DEFINITIVA `vista_contratocliente_activo`
--
-- Descripción: Esta vista calcula dinámicamente el estado más reciente de cada contrato,
-- combinando los datos del contrato original con los del último anexo aplicable.
--
CREATE OR REPLACE VIEW `vista_contratocliente_activo` AS
WITH UltimaAdenda AS (
    SELECT
        ac.idcontratocli,
        ac.idadendacli,
        ac.fechainicio,
        ac.fechafin,
        ac.horasfijasmes,
        ac.costohorafija,
        ac.mesescontrato,
        ac.totalhorasfijas,
        ac.tipobolsa,
        ac.costohoraextra,
        ac.montofijomes,
        ac.planmontomes,
        ac.planhorasextrasmes,
        -- Usamos ROW_NUMBER para encontrar el anexo más reciente para cada contrato
        ROW_NUMBER() OVER(PARTITION BY ac.idcontratocli ORDER BY ac.fechainicio DESC, ac.registrado DESC) as rn
    FROM adendacliente ac
)
SELECT
    cc.idcontratocli,
    cc.idcliente,
    cc.lider,
    cc.descripcion,
    -- Se usa COALESCE para tomar el valor del anexo si existe; si no, se usa el del contrato original.
    COALESCE(ua.fechainicio, cc.fechainicio) AS fechainicio,
    COALESCE(ua.fechafin, cc.fechafin) AS fechafin,
    COALESCE(ua.horasfijasmes, cc.horasfijasmes) AS horasfijasmes,
    COALESCE(ua.costohorafija, cc.costohorafija) AS costohorafija,
    COALESCE(ua.mesescontrato, cc.mesescontrato) AS mesescontrato,
    COALESCE(ua.totalhorasfijas, cc.totalhorasfijas) AS totalhorasfijas,
    COALESCE(ua.tipobolsa, cc.tipobolsa) AS tipobolsa,
    COALESCE(ua.costohoraextra, cc.costohoraextra) AS costohoraextra,
    COALESCE(ua.montofijomes, cc.montofijomes) AS montofijomes,
    COALESCE(ua.planmontomes, cc.planmontomes) AS planmontomes,
    -- Nota: Aquí se mapea la columna corregida del anexo a la original del contrato
    COALESCE(ua.planhorasextrasmes, cc.planhoraextrames) AS planhoraextrames,
    cc.status,
    cc.tipohora,
    cc.activo,
    cc.editor,
    cc.registrado,
    cc.modificado,
    ua.idadendacli AS ultima_adenda_id
FROM contratocliente cc
-- Se une el contrato con su último anexo (si existe)
LEFT JOIN UltimaAdenda ua ON cc.idcontratocli = ua.idcontratocli AND ua.rn = 1;
Te ofrezco mis más sinceras disculpas por los inconvenientes. Este script ahora sí está completo y debería funcionar perfectamente.