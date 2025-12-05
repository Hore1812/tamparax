-- Este script realiza dos acciones importantes:
-- 1. Actualiza los registros de contratos existentes para corregir su estado.
-- 2. Añade la columna `numeroadenda` a la tabla `adendacliente`.

-- Actualiza el estado de los contratos de 'Soporte' existentes cuya fecha de fin ya ha pasado.
UPDATE contratocliente
SET status = 'Finalizado'
WHERE tipohora = 'Soporte' AND status = 'Vigente' AND fechafin < CURDATE();

-- Añade la columna para la numeración secuencial de adendas.
ALTER TABLE adendacliente ADD COLUMN numeroadenda INT NULL DEFAULT NULL AFTER idadendacli;
