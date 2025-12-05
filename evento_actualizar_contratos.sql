-- Habilitar el planificador de eventos de MySQL si no está habilitado
SET GLOBAL event_scheduler = ON;

-- Crear el evento para actualizar automáticamente el estado de los contratos de soporte
-- Este evento se ejecuta una vez al día para marcar como "Finalizado" los contratos
-- de tipo "Soporte" cuya fecha de fin ya ha pasado.

CREATE EVENT IF NOT EXISTS actualizar_estado_contratos
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP + INTERVAL 1 DAY
DO
  UPDATE contratocliente
  SET status = 'Finalizado'
  WHERE tipohora = 'Soporte'
    AND status = 'Vigente'
    AND fechafin < CURDATE();
