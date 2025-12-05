-- Actualización de la base de datos para añadir el campo numeroadenda
-- Este script debe ejecutarse para que la nueva funcionalidad de numeración de adendas funcione correctamente.

ALTER TABLE adendacliente ADD COLUMN numeroadenda INT NULL DEFAULT NULL AFTER idadendacli;
