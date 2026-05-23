-- =============================================================================
-- 01-init.sql - Inicializacion de la base de datos del laboratorio.
-- Ejecutado automaticamente por la imagen de MariaDB la primera vez que arranca.
-- =============================================================================
-- Contiene credenciales DEBILES y datos sensibles FALSOS por diseno.
-- NO uses estos usuarios/contrasenas en ningun entorno real.
-- =============================================================================

-- Asegura el charset esperado por DVWA
ALTER DATABASE dvwa CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Base separada para ejercicios "corporativos"
CREATE DATABASE IF NOT EXISTS corp
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE corp;

-- -----------------------------------------------------------------------------
-- Tabla de empleados con datos ficticios
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS empleados (
  id            INT PRIMARY KEY AUTO_INCREMENT,
  nombre        VARCHAR(80)  NOT NULL,
  email         VARCHAR(120) NOT NULL,
  rol           VARCHAR(40)  NOT NULL,
  password_md5  CHAR(32)     NOT NULL,   -- hash debil a proposito (MD5 sin sal)
  creado_en     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO empleados (nombre, email, rol, password_md5) VALUES
  ('Admin Demo',     'admin@lab.local',     'admin',   MD5('admin123')),
  ('Alice Pentest',  'alice@lab.local',     'auditor', MD5('alice2025')),
  ('Bob Developer',  'bob@lab.local',       'dev',     MD5('bob_dev!')),
  ('Carol Support',  'carol@lab.local',     'soporte', MD5('carol99')),
  ('Dan Intern',     'dan.intern@lab.local','dev',     MD5('intern'));

-- -----------------------------------------------------------------------------
-- Tabla de tarjetas (datos sinteticos, no PII real)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tarjetas (
  id           INT PRIMARY KEY AUTO_INCREMENT,
  empleado_id  INT NOT NULL,
  pan          CHAR(16) NOT NULL,    -- numero ficticio
  cvv          CHAR(3)  NOT NULL,
  vencimiento  CHAR(5)  NOT NULL,    -- MM/AA
  CONSTRAINT fk_tarjetas_emp FOREIGN KEY (empleado_id) REFERENCES empleados(id)
);

INSERT INTO tarjetas (empleado_id, pan, cvv, vencimiento) VALUES
  (1, '4111111111111111', '123', '12/29'),
  (2, '5500000000000004', '321', '06/27'),
  (3, '340000000000009',  '999', '01/28');

-- -----------------------------------------------------------------------------
-- Notas internas con texto sospechoso (XSS almacenado para ejercicios)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS notas (
  id        INT PRIMARY KEY AUTO_INCREMENT,
  autor_id  INT NOT NULL,
  titulo    VARCHAR(120) NOT NULL,
  cuerpo    TEXT NOT NULL,
  creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO notas (autor_id, titulo, cuerpo) VALUES
  (1, 'Credenciales del proxy',
      'Recordatorio: el endpoint /nginx_status sigue abierto. Hay que cerrarlo.'),
  (2, 'TODO de hardening',
      'Pendiente: rotar contrasena de root de MySQL y desactivar phpMyAdmin.'),
  (3, 'Snippet con XSS',
      '<script>document.title="XSS-stored"</script>');

-- -----------------------------------------------------------------------------
-- Permisos: damos a 'dvwa' acceso tambien a la base 'corp' (mala practica).
-- -----------------------------------------------------------------------------
GRANT ALL PRIVILEGES ON corp.* TO 'dvwa'@'%';
FLUSH PRIVILEGES;
