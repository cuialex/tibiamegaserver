-- Ajustes de MyAAC usados en tibiaserver.ots.ovh
-- Ejecutar DESPUES de instalar MyAAC. Ajusta status_ip a la IP publica de tu servidor.
INSERT INTO myaac_settings (name, `key`, value) VALUES
 ('core','template','tibiacom'),
 ('core','template_allow_change','false'),
 ('core','status_ip','2.31.84.59'),
 ('core','status_port','7176');
-- El menu NO va en este SQL: en el admin (Menus) pulsa "Reset Menus to default".
-- Si ya existen filas con esas claves, usa UPDATE en lugar de INSERT.
