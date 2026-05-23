-- =============================================================================
-- 02-weak-users.sql - Usuarios MySQL debiles (intencional, fines academicos)
-- =============================================================================

-- Usuario sin contrasena (clasico)
CREATE USER IF NOT EXISTS 'guest'@'%' IDENTIFIED BY '';
GRANT SELECT ON corp.* TO 'guest'@'%';

-- Usuario con contrasena identica al nombre
CREATE USER IF NOT EXISTS 'reporting'@'%' IDENTIFIED BY 'reporting';
GRANT SELECT ON corp.* TO 'reporting'@'%';

-- Usuario con FILE privilege (peligroso: permite LOAD_FILE / INTO OUTFILE)
CREATE USER IF NOT EXISTS 'backup'@'%' IDENTIFIED BY 'backup123';
GRANT SELECT, FILE ON *.* TO 'backup'@'%';

FLUSH PRIVILEGES;
