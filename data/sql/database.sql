-- phpMyAdmin SQL Dump
-- version 4.5.2
-- http://www.phpmyadmin.net
--
-- Servidor: localhost
-- Tiempo de generación: 26-12-2016 a las 19:44:37
-- Versión del servidor: 10.1.9-MariaDB
-- Versión de PHP: 5.5.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `qualisoft_dev`
--
CREATE DATABASE IF NOT EXISTS `qualisoft_dev` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
USE `qualisoft_dev`;

DELIMITER $$
--
-- Procedimientos
--
DROP PROCEDURE IF EXISTS `procedure_addRecord`$$
CREATE DEFINER=`diego_torres`@`localhost` PROCEDURE `procedure_addRecord` (IN `param_table` VARCHAR(25), IN `param_data` TEXT)  BEGIN

/* @diegotorres50: este procedimiento recibe el nombre de una tabla mysql y un texto formateado
para armar una senetncia sql del insert de un registro

param_table = nombre de la tabla donde se hara insert de un registro;

param_data = texto con los datos del registro a insertar, cada campo esta compueste de:

	- El nombre de la columna.
    - El valor de la columna
    - El tipo de dato de la columna
    
Cada campo debe estar separado por el caracter '&' y cada propiedad del campo debe estar separada
por el caracter '@'

Ejemplo: id@6@integer&name@diego torres@string
*/

DECLARE _TOTAL_FILAS INT DEFAULT 0; /* Cantidad de campos a insertar del registro */
DECLARE _INDEX_FILA INT DEFAULT 0; /* Controla el orden del campo que estamos armando en el query insert */
DECLARE _FILA VARCHAR(50); /* Apunta a la informacion de un campo y sus 3 propiedades */

DECLARE _COL_ID VARCHAR(50); /* Indica el nombre de la columna actual */
DECLARE _COL_VAL VARCHAR(50); /* Indica el valor de la columna */
DECLARE _COL_TYPE VARCHAR(50); /* Indica el tipo de dato de esa columna */

DECLARE STMT_IDS TEXT; /* Concatena el query insert con los nombres de las columnas */
DECLARE STMT_VALUES TEXT; /* Concatena el query insert con los valores de las columnas */
DECLARE STMT_QUERY TEXT; /* Concatena todo el query insert para preparar su ejecucion en mysql */

SET STMT_IDS = ''; /* Iniciamos valores vacios para evitar el null al concatenar */
SET STMT_VALUES = ''; /* Iniciamos valores vacios para evitar el null al concatenar */

/* Contamos cuantos campos se armaran en el query, cada campo con sus 3 propiedades
deberia estar separado por &*/
SET _TOTAL_FILAS = LENGTH(param_data) - LENGTH(REPLACE(param_data, '&', '')) + 1;

/* Iniciamos un bucle controlado para recorrer los campos*/
_LEER_FILAS: LOOP
	
	SET _INDEX_FILA := _INDEX_FILA + 1;	/* Controlamos la posicion del campo donde estamos*/
    
    /* Extraemos un campo y sus 3 propiedades */
    SET _FILA := TRIM(SPLIT_STR(param_data, '&', _INDEX_FILA)); /*OJO, SPLIT_STR() ES UNA FUNCION CUSTOM */
    
    /* A cada campo extraido sacamos sus 3 propiedades */
    SET _COL_ID = TRIM(SPLIT_STR(_FILA, '#', 1)); /* nombre de la columna */
    SET _COL_VAL = TRIM(SPLIT_STR(_FILA, '#', 2)); /* valor de la columna */
    SET _COL_TYPE = TRIM(SPLIT_STR(_FILA, '#', 3)); /* tipo de dato*/
    
    /* armamos el query */
    SET STMT_IDS := CONCAT(STMT_IDS, '`', _COL_ID, '`', IF(_INDEX_FILA != _TOTAL_FILAS, ',', ''));
	SET STMT_VALUES := CONCAT(STMT_VALUES, IF(_COL_TYPE = 'string', '\'', ''), _COL_VAL, IF(_COL_TYPE = 'string', '\'', ''), IF(_INDEX_FILA != _TOTAL_FILAS, ',', ''));
    
    /* cuando se llegue al ultimo campo detenemos el bucle*/
	IF (_INDEX_FILA = _TOTAL_FILAS) THEN
		LEAVE _LEER_FILAS;
	END IF;

END LOOP;

/* armamos todo el query del insert */
SET @STMT_QUERY = CONCAT(
'INSERT INTO `', param_table,'` (',
STMT_IDS,
') VALUES (',
STMT_VALUES,
');');

/* Lo ejecutamos */
PREPARE _QUERY FROM @STMT_QUERY;
EXECUTE _QUERY;
DEALLOCATE PREPARE _QUERY;

END$$

DROP PROCEDURE IF EXISTS `procedure_closeLogin`$$
CREATE DEFINER=`diego_torres`@`localhost` PROCEDURE `procedure_closeLogin` (IN `param_login_id` BIGINT(20))  BEGIN
	/* @diegotorres50: este procedimiento cambia el estado de la session registrada en la
    base de datos a 'closed' para asi cerrar la sesion en el sistema*/
    update 
          logins     set 
    	login_status='CLOSED',         login_notes='THIS SESSION WAS CLOSED BY USER',         login_closed=NOW()     where 
    	login_id=param_login_id and         login_status = 'OPENED'; END$$

DROP PROCEDURE IF EXISTS `procedure_findAll`$$
CREATE DEFINER=`diego_torres`@`localhost` PROCEDURE `procedure_findAll` (IN `_tableName` VARCHAR(28), IN `_databaseName` VARCHAR(28), IN `_search` TEXT, IN `_orderby` VARCHAR(28), IN `_offset` INT(10), IN `_rowcount` SMALLINT(3))  BEGIN
/* @diegotorres50: este procedimiento que facilita la busqueda de resultados
sobre una tabla y un patron de busqueda */	
 DECLARE finished INT DEFAULT FALSE ;
       DECLARE columnName VARCHAR ( 28 ) ;
       DECLARE stmtFields TEXT ;
       DECLARE columnNames CURSOR FOR
              SELECT DISTINCT `COLUMN_NAME` FROM `information_schema`.`COLUMNS`
              WHERE `TABLE_NAME` = _tableName AND `TABLE_SCHEMA` = _databaseName ORDER BY `ORDINAL_POSITION` ;
       DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = TRUE;
       SET stmtFields = '' ;
       OPEN columnNames ;
       readColumns: LOOP
              FETCH columnNames INTO columnName ;
              IF finished THEN
                     LEAVE readColumns ;
              END IF;
              SET stmtFields = CONCAT(
                     stmtFields , IF ( LENGTH( stmtFields ) > 0 , ' OR' , ''  ) ,
                     ' `', _tableName ,'`.`' , columnName , '` LIKE "%' , _search , '%"'
              ) ;
              #SET stmtFields = "users.user_id = 'diegotorres50'";
       END LOOP;

       SET @stmtQueryForDropTable := CONCAT ( 'DROP TEMPORARY TABLE IF EXISTS `TMP_', _tableName,'`;') ;
       PREPARE stmt FROM @stmtQueryForDropTable ;
       EXECUTE stmt ;

       SET @stmtQueryForCreateTable := CONCAT ( 'CREATE TEMPORARY TABLE IF NOT EXISTS `TMP_', _tableName,'` AS SELECT * FROM `' , _tableName , '` WHERE ' , stmtFields, ' ORDER BY ' , _orderby , ' LIMIT ' , _offset , ' , ' , _rowcount) ;
       PREPARE stmt FROM @stmtQueryForCreateTable ;
       EXECUTE stmt ;
       
       SET @stmtQueryForDropTotalTable := CONCAT ( 'DROP TEMPORARY TABLE IF EXISTS `COUNT_', _tableName,'`;') ;
       PREPARE stmt FROM @stmtQueryForDropTotalTable ;
       EXECUTE stmt ;       
       
       SET @stmtQueryForCountTable := CONCAT ( 'CREATE TEMPORARY TABLE IF NOT EXISTS `COUNT_' , _tableName , '` AS SELECT count(*) as total FROM `' , _tableName , '` WHERE ' , stmtFields) ;
       PREPARE stmt FROM @stmtQueryForCountTable ;
       EXECUTE stmt ;       
       
       CLOSE columnNames ;

END$$

DROP PROCEDURE IF EXISTS `procedure_getLoginId`$$
CREATE DEFINER=`diego_torres`@`localhost` PROCEDURE `procedure_getLoginId` (IN `param_login_user_id` VARCHAR(20), IN `param_login_time` DATETIME, OUT `param_login_id` BIGINT(20))  BEGIN
/* @diegotorres50: este procedimiento devuelve el id de la sesion que se registra en la
base de datos en el momento que un usuario inicia sesion web*/
	select distinct(login_id) 	into param_login_id     from `logins`     where 
		login_user_id=param_login_user_id and         login_time=param_login_time         order by login_user_id, login_time; END$$

DROP PROCEDURE IF EXISTS `procedure_getUserName`$$
CREATE DEFINER=`diego_torres`@`localhost` PROCEDURE `procedure_getUserName` (IN `_userId` VARCHAR(20), OUT `_userName` VARCHAR(200))  BEGIN

	/* @diegotorres50: este procedimiento obtiene el username de un usuario
    partiendo del id del usuario*/
    
	select 

		users.user_name
            
	into _userName
        
	from
         
		users
            
	where    
            
		users.user_id = _userId
            
	order by
        
		users.user_id
            
	
    LIMIT 1;    

END$$

DROP PROCEDURE IF EXISTS `procedure_getColumnNames`$$
CREATE DEFINER=`diego_torres`@`localhost` PROCEDURE `procedure_getColumnNames` (IN `tableName` VARCHAR(28), IN `databaseName` VARCHAR(28), OUT `columnsAlias` VARCHAR(200))  BEGIN
/* @diegotorres50: este procedimiento que facilita extraer los nombres de columna para una viata o tabla */	
 DECLARE finished INT DEFAULT FALSE ;
       DECLARE columnName VARCHAR ( 28 ) ;
       DECLARE stmtFields TEXT ;
       DECLARE columnNames CURSOR FOR
              SELECT DISTINCT `COLUMN_NAME` FROM `information_schema`.`COLUMNS`
              WHERE `TABLE_NAME` = tableName AND `TABLE_SCHEMA` = databaseName ORDER BY `ORDINAL_POSITION` ;
       DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = TRUE;
       SET stmtFields = '' ;
       OPEN columnNames ;
       readColumns: LOOP
              FETCH columnNames INTO columnName ;
              IF finished THEN
                     LEAVE readColumns ;
              END IF;
              SET stmtFields = CONCAT(stmtFields, IF ( LENGTH( stmtFields ) > 0 , ',' , ''  ), columnName) ;
       END LOOP;

       SET columnsAlias =  stmtFields;
       
       CLOSE columnNames ;

END$$

DROP PROCEDURE IF EXISTS `procedure_setToPurge`$$
CREATE DEFINER=`diego_torres`@`localhost` PROCEDURE `procedure_setToPurge` (IN `param_table_name` VARCHAR(28), IN `param_record_id` VARCHAR(28), IN `param_id_value` VARCHAR(28))  BEGIN
	/*
    @diegotorres50: este procedimiento cambia el estado de purga de registro a '1' de manera
    que el registro se filtre en todas las consultas para ocultarlo y en otro procedimiento
    borrarlo por completo de la tabla
    */
	SET @stmt = CONCAT ( 'UPDATE `' , param_table_name , '` SET `purged` = 1 WHERE `' , param_record_id , '` = ?;') ;
	SET @_id_value = param_id_value;
    PREPARE _query FROM @stmt;
	EXECUTE _query USING @_id_value;
	DEALLOCATE PREPARE _query;      
END$$

--
-- Funciones
--
DROP FUNCTION IF EXISTS `SPLIT_STR`$$
CREATE DEFINER=`diego_torres`@`localhost` FUNCTION `SPLIT_STR` (`x` VARCHAR(255), `delim` VARCHAR(12), `pos` INT) RETURNS VARCHAR(255) CHARSET utf8 BEGIN
/*

http://blog.fedecarg.com/2009/02/22/mysql-split-string-function/

SELECT SPLIT_STR('a|bb|ccc|dd', '|', 3) as third;

+-------+
| third |
+-------+
| ccc   |
+-------+
*/
RETURN REPLACE(SUBSTRING(SUBSTRING_INDEX(x, delim, pos),
       LENGTH(SUBSTRING_INDEX(x, delim, pos -1)) + 1),
       delim, '');
END$$

DROP FUNCTION IF EXISTS `testing`$$
CREATE DEFINER=`diego_torres`@`localhost` FUNCTION `testing` () RETURNS INT(11) BEGIN

RETURN 1;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `centers`
--

DROP TABLE IF EXISTS `centers`;
CREATE TABLE `centers` (
  `center_id` varchar(20) NOT NULL COMMENT 'Indentifica el centro al que pertenece la informacion del sistema de informacion',
  `center_name` varchar(200) NOT NULL DEFAULT 'GIVE ME A NAME' COMMENT 'Nombre descriptivo del centro de informacion',
  `center_status` set('ACTIVE','INACTIVE') NOT NULL DEFAULT 'ACTIVE' COMMENT 'Estado general del centro de informalcion',
  `center_notes` text COMMENT 'Notas y observaciones del centro de informacion',
  `center_modifiedsince` datetime DEFAULT NULL,
  `center_modifiedby` varchar(20) DEFAULT NULL,
  `center_createdsince` datetime DEFAULT NULL,
  `center_createdby` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Centros principales de agrupacion de informacion, son como empresas';

--
-- Volcado de datos para la tabla `centers`
--

INSERT INTO `centers` (`center_id`, `center_name`, `center_status`, `center_notes`, `center_modifiedsince`, `center_modifiedby`, `center_createdsince`, `center_createdby`) VALUES
('CENTRO 4', 'CENTRO CUATRO', 'ACTIVE', NULL, NULL, NULL, NULL, NULL),
('CENTRO1', 'CENTRO UNO', 'ACTIVE', NULL, NULL, NULL, NULL, NULL),
('CENTRO3', 'CENTRO TRES', 'ACTIVE', NULL, NULL, NULL, NULL, NULL),
('CENTRO5', 'CENTRO CINCO', 'INACTIVE', NULL, NULL, NULL, NULL, NULL),
('CENTRO_2', 'CENTRO DOS', 'ACTIVE', NULL, NULL, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `logins`
--

DROP TABLE IF EXISTS `logins`;
CREATE TABLE `logins` (
  `login_user_id` varchar(20) NOT NULL DEFAULT 'UNKNOWN' COMMENT 'Identificador del usuario quien crea la sesion, no la relacionamos como clave foranea para que el mantenimiento de esta tabla no tenga conflistos de relacionaes',
  `login_time` datetime NOT NULL DEFAULT '0000-00-00 00:00:00' COMMENT 'Fecha y hora en que se crea la sesion, es el complemento con el user:id para generar una llave primaria.',
  `login_id` bigint(20) UNSIGNED ZEROFILL NOT NULL COMMENT 'Un indice de secuencia que ayuda a indexar la tabla y a las busquedas de una sesion en particular',
  `login_status` set('CLOSED','OPENED') NOT NULL DEFAULT 'OPENED' COMMENT 'Estado de la sesion actual, que puede representar que la sesion esta viva o ya fue cerrada por el usuario',
  `login_useragent` text COMMENT 'userAgent del navegador cliente',
  `login_language` varchar(20) DEFAULT 'UNKNOWN' COMMENT 'Idioma local del usuario detectado en el cliente',
  `login_platform` varchar(45) DEFAULT 'UNKNOWN' COMMENT 'Plataforma local del usuario, por ejemplo linux o windows',
  `login_origin` varchar(100) DEFAULT 'UNKNOWN' COMMENT 'Dominio detectado con protocolo, por ejemplo http://www.qualisoft.com',
  `login_closed` datetime DEFAULT '0000-00-00 00:00:00' COMMENT 'Fecha hora del cierre de la sesion',
  `login_notes` varchar(50) DEFAULT NULL COMMENT 'Nota general de la sesion'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Registro de logins de usuario, conocido igual como registro de sesiones';

--
-- Volcado de datos para la tabla `logins`
--

INSERT INTO `logins` (`login_user_id`, `login_time`, `login_id`, `login_status`, `login_useragent`, `login_language`, `login_platform`, `login_origin`, `login_closed`, `login_notes`) VALUES
('clayanine', '2015-06-27 02:40:38', 00000000000000000041, 'CLOSED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '2015-06-26 19:46:56', 'THIS SESSION WAS CLOSED BY USER'),
('clayanine', '2015-06-27 02:47:16', 00000000000000000042, 'CLOSED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '2015-06-26 19:50:04', 'THIS SESSION WAS CLOSED BY USER'),
('clayanine', '2015-06-27 02:50:35', 00000000000000000043, 'CLOSED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '2015-06-26 19:51:44', 'THIS SESSION WAS CLOSED BY USER'),
('clayanine', '2015-06-28 01:05:21', 00000000000000000046, 'CLOSED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '2015-06-27 19:53:48', 'THIS SESSION WAS CLOSED BY USER'),
('clayanine', '2015-06-28 02:55:01', 00000000000000000048, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('clayanine', '2015-06-28 20:32:56', 00000000000000000050, 'CLOSED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '2015-06-28 13:35:49', 'THIS SESSION WAS CLOSED BY USER'),
('clayanine', '2015-06-29 01:19:15', 00000000000000000053, 'CLOSED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '2015-06-28 18:19:39', 'THIS SESSION WAS CLOSED BY USER'),
('clayanine', '2015-06-29 20:01:07', 00000000000000000056, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-06-23 04:44:12', 00000000000000000001, 'CLOSED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '2015-06-24 20:20:59', 'THIS SESSION WAS CLOSED BY USER'),
('diegotorres50', '2015-06-23 05:01:11', 00000000000000000002, 'CLOSED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '2016-02-13 15:46:02', 'THIS SESSION WAS CLOSED BY USER'),
('diegotorres50', '2015-06-23 20:18:34', 00000000000000000003, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-06-24 01:30:57', 00000000000000000004, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-06-24 03:22:39', 00000000000000000005, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-06-24 03:24:18', 00000000000000000006, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-06-24 03:24:47', 00000000000000000007, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-06-24 03:26:25', 00000000000000000008, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-06-24 03:34:11', 00000000000000000009, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-06-24 03:36:54', 00000000000000000010, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-06-24 03:41:19', 00000000000000000011, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-06-24 03:44:13', 00000000000000000012, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-06-24 03:46:58', 00000000000000000013, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-06-24 03:53:42', 00000000000000000014, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-06-24 03:54:29', 00000000000000000015, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-06-24 04:28:39', 00000000000000000016, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-06-24 04:35:50', 00000000000000000017, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-06-24 04:42:00', 00000000000000000018, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-06-24 04:45:53', 00000000000000000019, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-06-24 04:58:08', 00000000000000000020, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-06-24 05:03:55', 00000000000000000021, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-06-24 05:05:08', 00000000000000000022, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-06-24 05:06:07', 00000000000000000023, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-06-24 05:08:07', 00000000000000000024, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-06-24 05:10:20', 00000000000000000025, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-06-24 05:12:56', 00000000000000000026, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-06-24 05:21:16', 00000000000000000027, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-06-24 05:21:58', 00000000000000000028, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-06-24 05:24:42', 00000000000000000029, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-06-24 05:25:09', 00000000000000000030, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-06-25 01:41:08', 00000000000000000031, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-06-25 01:46:41', 00000000000000000032, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-06-25 01:55:43', 00000000000000000033, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-06-25 02:10:51', 00000000000000000034, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-06-25 03:48:59', 00000000000000000035, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-06-25 03:51:22', 00000000000000000036, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-06-25 03:54:24', 00000000000000000037, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-06-25 03:56:07', 00000000000000000038, 'CLOSED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '2015-06-24 20:56:16', 'THIS SESSION WAS CLOSED BY USER'),
('diegotorres50', '2015-06-25 03:59:48', 00000000000000000039, 'CLOSED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '2015-06-24 20:59:54', 'THIS SESSION WAS CLOSED BY USER'),
('diegotorres50', '2015-06-27 02:19:01', 00000000000000000040, 'CLOSED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '2015-06-26 19:40:12', 'THIS SESSION WAS CLOSED BY USER'),
('diegotorres50', '2015-06-27 02:51:58', 00000000000000000044, 'CLOSED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '2015-06-26 19:53:19', 'THIS SESSION WAS CLOSED BY USER'),
('diegotorres50', '2015-06-28 01:04:49', 00000000000000000045, 'CLOSED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '2015-06-27 18:05:00', 'THIS SESSION WAS CLOSED BY USER'),
('diegotorres50', '2015-06-28 02:53:59', 00000000000000000047, 'CLOSED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '2015-06-27 19:54:25', 'THIS SESSION WAS CLOSED BY USER'),
('diegotorres50', '2015-06-28 20:31:46', 00000000000000000049, 'CLOSED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '2015-06-28 13:32:37', 'THIS SESSION WAS CLOSED BY USER'),
('diegotorres50', '2015-06-28 20:36:04', 00000000000000000051, 'CLOSED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '2015-06-28 13:38:47', 'THIS SESSION WAS CLOSED BY USER'),
('diegotorres50', '2015-06-28 20:39:01', 00000000000000000052, 'CLOSED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '2015-06-28 18:18:44', 'THIS SESSION WAS CLOSED BY USER'),
('diegotorres50', '2015-06-29 01:20:02', 00000000000000000054, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-06-29 18:43:53', 00000000000000000055, 'CLOSED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '2015-06-29 13:00:43', 'THIS SESSION WAS CLOSED BY USER'),
('diegotorres50', '2015-06-30 01:34:49', 00000000000000000057, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-07-01 01:27:40', 00000000000000000058, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-07-01 19:40:09', 00000000000000000059, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2015-07-03 02:56:32', 00000000000000000060, 'CLOSED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '2015-07-02 20:00:10', 'THIS SESSION WAS CLOSED BY USER'),
('diegotorres50', '2015-07-03 03:00:32', 00000000000000000061, 'CLOSED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '2015-07-02 20:02:56', 'THIS SESSION WAS CLOSED BY USER'),
('diegotorres50', '2015-07-03 03:03:07', 00000000000000000062, 'CLOSED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '2015-07-02 20:07:53', 'THIS SESSION WAS CLOSED BY USER'),
('diegotorres50', '2015-07-03 03:08:04', 00000000000000000063, 'CLOSED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '2015-07-02 20:09:00', 'THIS SESSION WAS CLOSED BY USER'),
('diegotorres50', '2015-07-03 03:09:11', 00000000000000000064, 'CLOSED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '2015-07-02 20:09:58', 'THIS SESSION WAS CLOSED BY USER'),
('diegotorres50', '2015-07-03 03:10:09', 00000000000000000065, 'CLOSED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '2015-07-02 20:13:21', 'THIS SESSION WAS CLOSED BY USER'),
('diegotorres50', '2015-07-03 03:13:35', 00000000000000000066, 'CLOSED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '2015-07-02 20:14:07', 'THIS SESSION WAS CLOSED BY USER'),
('diegotorres50', '2015-07-03 03:14:20', 00000000000000000067, 'CLOSED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '2015-07-02 20:57:57', 'THIS SESSION WAS CLOSED BY USER'),
('diegotorres50', '2015-07-03 03:58:39', 00000000000000000068, 'CLOSED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '2015-07-02 20:59:16', 'THIS SESSION WAS CLOSED BY USER'),
('diegotorres50', '2016-02-14 01:47:01', 00000000000000000069, 'CLOSED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '2016-02-13 19:49:29', 'THIS SESSION WAS CLOSED BY USER'),
('diegotorres50', '2016-02-21 00:28:06', 00000000000000000070, 'CLOSED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '2016-02-20 22:08:20', 'THIS SESSION WAS CLOSED BY USER'),
('diegotorres50', '2016-02-21 04:09:01', 00000000000000000071, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2016-02-21 16:51:53', 00000000000000000072, 'CLOSED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '2016-02-21 16:49:49', 'THIS SESSION WAS CLOSED BY USER'),
('diegotorres50', '2016-02-21 22:50:02', 00000000000000000073, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2016-02-22 19:20:53', 00000000000000000074, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2016-02-23 01:50:03', 00000000000000000075, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2016-02-24 18:32:35', 00000000000000000076, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2016-02-25 01:57:06', 00000000000000000077, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2016-02-25 19:05:22', 00000000000000000078, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2016-02-26 00:29:52', 00000000000000000079, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2016-02-27 00:11:17', 00000000000000000080, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2016-02-27 17:31:43', 00000000000000000081, 'CLOSED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '2016-02-27 11:32:38', 'THIS SESSION WAS CLOSED BY USER'),
('diegotorres50', '2016-02-27 17:32:47', 00000000000000000082, 'CLOSED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '2016-02-27 11:41:51', 'THIS SESSION WAS CLOSED BY USER'),
('diegotorres50', '2016-02-27 17:42:11', 00000000000000000083, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2016-02-27 18:16:01', 00000000000000000084, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2016-02-27 18:28:14', 00000000000000000085, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2016-02-27 22:22:08', 00000000000000000086, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2016-02-27 22:39:36', 00000000000000000087, 'CLOSED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '2016-02-27 20:22:00', 'THIS SESSION WAS CLOSED BY USER'),
('diegotorres50', '2016-02-28 02:22:40', 00000000000000000088, 'CLOSED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '2016-02-27 20:26:12', 'THIS SESSION WAS CLOSED BY USER'),
('diegotorres50', '2016-03-01 01:05:51', 00000000000000000089, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2016-03-01 01:44:53', 00000000000000000090, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2016-03-03 02:28:28', 00000000000000000091, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2016-03-05 17:50:02', 00000000000000000092, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2016-03-06 00:56:09', 00000000000000000093, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE'),
('diegotorres50', '2016-03-08 00:13:31', 00000000000000000094, 'OPENED', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', 'PENDIENTE', '0000-00-00 00:00:00', 'PENDIENTE');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `system`
--

DROP TABLE IF EXISTS `system`;
CREATE TABLE `system` (
  `system_status` set('ACTIVE','INACTIVE') NOT NULL DEFAULT 'INACTIVE' COMMENT 'Define si el sistema esta activo o no para usarlo',
  `system_maintenance_msg` text NOT NULL COMMENT 'El texto por defecto que se muestra',
  `system_version` tinyint(4) UNSIGNED NOT NULL DEFAULT '1' COMMENT 'Versión del sistema'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Información general de la aplicación';

--
-- Volcado de datos para la tabla `system`
--

INSERT INTO `system` (`system_status`, `system_maintenance_msg`, `system_version`) VALUES
('', 'El sistema no esta disponible en el momento por tareas de mantenimiento. \r\n\r\nPor favor intente mas tarde con contacte al administrador del sistema.', 1),
('ACTIVE', 'El sistema no esta disponible en el momento por tareas de mantenimiento. \r\n\r\nPor favor intente mas tarde con contacte al administrador del sistema.', 1),
('ACTIVE', 'El sistema no esta disponible en el momento por tareas de mantenimiento. \r\n\r\nPor favor intente mas tarde con contacte al administrador del sistema.', 1),
('ACTIVE', 'El sistema no esta disponible en el momento por tareas de mantenimiento. \r\n\r\nPor favor intente mas tarde con contacte al administrador del sistema.', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `testing`
--

DROP TABLE IF EXISTS `testing`;
CREATE TABLE `testing` (
  `id` int(11) NOT NULL,
  `name` varchar(45) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `users`
--

DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `user_id` varchar(20) NOT NULL COMMENT 'Identificador unico del usuario, por ejemplo: diegotorres50',
  `user_document` varchar(15) DEFAULT NULL COMMENT 'Documento unico opcional para identificar al usuario, por ejemplo el numero de cedula o pasaporte',
  `user_status` set('ACTIVE','INACTIVE') NOT NULL DEFAULT 'INACTIVE' COMMENT 'Debe ser active o inactive',
  `user_name` varchar(200) NOT NULL COMMENT 'Nombre y apellido del usuario',
  `user_mail` varchar(200) NOT NULL COMMENT 'Correo electronico del usuario, deberia ser unico entre todos los usuarios',
  `user_pass` varchar(512) NOT NULL COMMENT 'Clave del usuario',
  `user_language` char(3) NOT NULL DEFAULT 'es' COMMENT 'Idioma opcional, se podria usar en un futuro para las traducciones del sistema.',
  `user_debugger` tinyint(1) DEFAULT '0' COMMENT '1 para determinar que el usuario puede ver datos ocultos en la interface de qualisofti como variables de prueba, esto ayudaria a depurar el crm en tiempo de ejecucion',
  `user_secretquestion` varchar(200) DEFAULT NULL COMMENT 'Pregunta secreta para validar la recuperacion de la clave',
  `user_secretanswer` varchar(200) DEFAULT NULL COMMENT 'Respuesta secreta para validar la recuperacion de la clave',
  `user_birthday` date DEFAULT NULL COMMENT 'Fecha de cumpleanios',
  `user_lastactivation` date DEFAULT NULL COMMENT 'Muestra la fecha desde que el usuario fue activado en el sistema',
  `user_alloweddays` int(3) DEFAULT NULL COMMENT 'Dias permitidos, si se quiere restringir el tiempo de activacion del usuario.',
  `user_photo` blob COMMENT 'Guarda en binario la imagen de perfil de usuario',
  `user_role` set('NONE','BASIC','STANDARD','ADMIN','MASTER') DEFAULT 'NONE' COMMENT 'Determina el role de usuario para la logica de accesos a los diferentes modulos del sistema.',
  `user_notes` text COMMENT 'Observaciones generales del usuario',
  `user_lastmovementdate` datetime DEFAULT NULL COMMENT 'Fecha y hora en que se toco el registro en la base de datos',
  `user_lastmovementip` varchar(15) DEFAULT NULL COMMENT 'Direccion ip para monitorear la ubicacion de quien toca el registro',
  `user_lastmovementwho` varchar(10) DEFAULT NULL COMMENT 'User Id del usuario que toca el registro',
  `purged` bit(1) DEFAULT b'0' COMMENT '0 = el registro de la tabla esta disponible para consultas, 1 = el registro debe ser filtrado para no mostrarse y deberia ser borrado por un procedimiento del administrador del sistema'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='App users';

--
-- Volcado de datos para la tabla `users`
--

INSERT INTO `users` (`user_id`, `user_document`, `user_status`, `user_name`, `user_mail`, `user_pass`, `user_language`, `user_debugger`, `user_secretquestion`, `user_secretanswer`, `user_birthday`, `user_lastactivation`, `user_alloweddays`, `user_photo`, `user_role`, `user_notes`, `user_lastmovementdate`, `user_lastmovementip`, `user_lastmovementwho`, `purged`) VALUES
('alejandro1', NULL, 'INACTIVE', 'Alejandra Suana', 'aleja@vass2.com', '14e1b600b1fd579f47433b88e8d85291', 'es', 0, NULL, NULL, NULL, NULL, NULL, NULL, 'NONE', NULL, '2016-03-05 20:21:15', NULL, NULL, b'0'),
('alejota', NULL, 'INACTIVE', 'Alejandra Suana', 'alejita@buuu.com', '0baa894d310523b1671fef2c76914ac1', 'es', 0, NULL, NULL, NULL, NULL, NULL, NULL, 'NONE', NULL, '2016-03-05 19:45:09', NULL, NULL, b'0'),
('alexandra', NULL, 'INACTIVE', 'Alexandra Barrera', 'aleja@vass.com', '14e1b600b1fd579f47433b88e8d85291', 'es', 0, NULL, NULL, NULL, NULL, NULL, NULL, 'NONE', NULL, '2016-03-05 19:23:02', NULL, NULL, b'0'),
('clayanine1', '52234223', 'ACTIVE', 'Claudia Yanneth Neira', 'clayanine@hotmail.com', '14e1b600b1fd579f47433b88e8d85291', 'es', 0, 'nombre de bebe', 'Mariana', NULL, NULL, 30, NULL, 'NONE,BASIC,ADMIN', 'Otro usuario', '2015-07-02 20:57:06', NULL, NULL, b'0'),
('diegotorres50', '80123856', 'ACTIVE', 'Diego Torres', 'diegotorres50@hotmail.com', '14e1b600b1fd579f47433b88e8d85291', 'es', 0, 'nombre de mascota de padres', 'falkor', '0000-00-00', NULL, 30, NULL, 'MASTER', 'Usuario de prueba', '2015-06-28 13:38:39', NULL, NULL, b'0'),
('marianita', NULL, 'INACTIVE', 'Mariana Torres Neira', 'mariana@hotmail.com', '1f32aa4c9a1d2ea010adcf2348166a04', 'es', 0, NULL, NULL, NULL, NULL, NULL, NULL, 'NONE', NULL, '2016-03-05 19:50:46', NULL, NULL, b'0'),
('user1', NULL, 'INACTIVE', '', 'user1', '74be16979710d4c4e7c6647856088456', 'es', 0, NULL, NULL, NULL, NULL, NULL, NULL, 'NONE', NULL, '2016-03-05 20:30:56', NULL, NULL, b'0'),
('user10', NULL, 'INACTIVE', '', 'user10', '74be16979710d4c4e7c6647856088456', 'es', 0, NULL, NULL, NULL, NULL, NULL, NULL, 'NONE', NULL, '2015-06-29 19:38:33', NULL, NULL, b'0'),
('user11', NULL, 'INACTIVE', '', 'user11', '74be16979710d4c4e7c6647856088456', 'es', 0, NULL, NULL, NULL, NULL, NULL, NULL, 'NONE', NULL, '2015-06-29 19:38:33', NULL, NULL, b'0'),
('user12', NULL, 'INACTIVE', '', 'user12', '74be16979710d4c4e7c6647856088456', 'es', 0, NULL, NULL, NULL, NULL, NULL, NULL, 'NONE', NULL, '2015-06-29 19:38:33', NULL, NULL, b'0'),
('user13', NULL, 'INACTIVE', '', 'user13', '74be16979710d4c4e7c6647856088456', 'es', 0, NULL, NULL, NULL, NULL, NULL, NULL, 'NONE', NULL, '2015-06-29 19:38:33', NULL, NULL, b'0'),
('user14', NULL, 'INACTIVE', '', 'user14', '74be16979710d4c4e7c6647856088456', 'es', 0, NULL, NULL, NULL, NULL, NULL, NULL, 'NONE', NULL, '2015-06-29 19:38:33', NULL, NULL, b'0'),
('user15', NULL, 'INACTIVE', '', 'user15', '74be16979710d4c4e7c6647856088456', 'es', 0, NULL, NULL, NULL, NULL, NULL, NULL, 'NONE', NULL, '2015-06-29 19:38:33', NULL, NULL, b'0'),
('user16', NULL, 'INACTIVE', '', 'user16', '74be16979710d4c4e7c6647856088456', 'es', 0, NULL, NULL, NULL, NULL, NULL, NULL, 'NONE', NULL, '2016-03-05 20:30:56', NULL, NULL, b'0'),
('user2', NULL, 'INACTIVE', '', 'user2', '74be16979710d4c4e7c6647856088456', 'es', 0, NULL, NULL, NULL, NULL, NULL, NULL, 'NONE', NULL, '2016-03-05 20:30:56', NULL, NULL, b'0'),
('user3', NULL, 'INACTIVE', '', 'user3', '74be16979710d4c4e7c6647856088456', 'es', 0, NULL, NULL, NULL, NULL, NULL, NULL, 'NONE', NULL, '2016-03-05 20:30:56', NULL, NULL, b'0'),
('user4', NULL, 'INACTIVE', '', 'user4', '74be16979710d4c4e7c6647856088456', 'es', 0, NULL, NULL, NULL, NULL, NULL, NULL, 'NONE', NULL, '2015-06-29 19:38:33', NULL, NULL, b'0'),
('user5', NULL, 'INACTIVE', '', 'user5', '74be16979710d4c4e7c6647856088456', 'es', 0, NULL, NULL, NULL, NULL, NULL, NULL, 'NONE', NULL, '2015-06-29 19:38:33', NULL, NULL, b'0'),
('user6', NULL, 'INACTIVE', '', 'user6', '74be16979710d4c4e7c6647856088456', 'es', 0, NULL, NULL, NULL, NULL, NULL, NULL, 'NONE', NULL, '2016-03-05 20:27:19', NULL, NULL, b'1'),
('user7', NULL, 'INACTIVE', '', 'user7', '74be16979710d4c4e7c6647856088456', 'es', 0, NULL, NULL, NULL, NULL, NULL, NULL, 'NONE', NULL, '2016-03-05 20:30:56', NULL, NULL, b'0'),
('user8', NULL, 'INACTIVE', '', 'user8', '74be16979710d4c4e7c6647856088456', 'es', 0, NULL, NULL, NULL, NULL, NULL, NULL, 'NONE', NULL, '2016-03-05 20:30:56', NULL, NULL, b'0'),
('user9', NULL, 'INACTIVE', '', 'user9', '74be16979710d4c4e7c6647856088456', 'es', 0, NULL, NULL, NULL, NULL, NULL, NULL, 'NONE', NULL, '2016-03-05 20:30:56', NULL, NULL, b'0');

--
-- Disparadores `users`
--
DROP TRIGGER IF EXISTS `users_before_ins_tr`;
DELIMITER $$
CREATE TRIGGER `users_before_ins_tr` BEFORE INSERT ON `users` FOR EACH ROW BEGIN

SET NEW.user_pass = MD5(MD5(NEW.user_pass));

set NEW.user_lastmovementdate=now();
END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `users_before_upd_tr`;
DELIMITER $$
CREATE TRIGGER `users_before_upd_tr` BEFORE UPDATE ON `users` FOR EACH ROW BEGIN

if NEW.user_pass <> old.user_pass then
	SET NEW.user_pass = MD5(MD5(NEW.user_pass)); end if;  

set NEW.user_lastmovementdate=now();
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `users_x_centers`
--

DROP TABLE IF EXISTS `users_x_centers`;
CREATE TABLE `users_x_centers` (
  `users_x_centers_user_id` varchar(20) NOT NULL COMMENT 'Identificador del usuario',
  `users_x_centers_user_name` varchar(200) DEFAULT 'GIVE ME A NAME' COMMENT 'Nombre del usuario',
  `users_x_centers_center_id` varchar(20) NOT NULL COMMENT 'Indetificador del centro principal de informacion',
  `users_x_centers_center_name` varchar(200) DEFAULT 'GIVE ME A NAME' COMMENT 'Nombre descriptivo del centro',
  `users_x_centers_notes` text COMMENT 'Observaciones generales',
  `users_x_centers_modifiedsince` datetime DEFAULT NULL,
  `users_x_centers_modifiedby` varchar(20) DEFAULT NULL,
  `users_x_centers_createdsince` datetime DEFAULT NULL,
  `users_x_centers_createdby` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Tabla hibrida de usuarios x empresas';

--
-- Volcado de datos para la tabla `users_x_centers`
--

INSERT INTO `users_x_centers` (`users_x_centers_user_id`, `users_x_centers_user_name`, `users_x_centers_center_id`, `users_x_centers_center_name`, `users_x_centers_notes`, `users_x_centers_modifiedsince`, `users_x_centers_modifiedby`, `users_x_centers_createdsince`, `users_x_centers_createdby`) VALUES
('clayanine1', 'Claudia Neira', 'centro1', 'GIVE ME A NAME', NULL, '2015-07-02 20:55:34', NULL, NULL, NULL),
('diegotorres50', 'Diego Torres', 'centro3', 'GIVE ME A NAME', NULL, '2015-07-02 20:55:16', NULL, NULL, NULL),
('diegotorres50', 'GIVE ME A NAME', 'CENTRO_2', 'GIVE ME A NAME', NULL, NULL, NULL, NULL, NULL);

--
-- Disparadores `users_x_centers`
--
DROP TRIGGER IF EXISTS `users_x_centers_BEFORE_UPDATE`;
DELIMITER $$
CREATE TRIGGER `users_x_centers_BEFORE_UPDATE` BEFORE UPDATE ON `users_x_centers` FOR EACH ROW BEGIN

Declare _userId VARCHAR(20);
Declare _userName VARCHAR(200);

set NEW.users_x_centers_modifiedsince = now();

set _userId = new.users_x_centers_user_id;


CALL `procedure_getUserName`(_userId, @userName);


select @userName


into _userName;


set new.users_x_centers_user_name = _userName;

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `view_users`
--
DROP VIEW IF EXISTS `view_users`;
CREATE TABLE `view_users` (
`id` varchar(20)
,`estado` set('ACTIVE','INACTIVE')
,`nombre` varchar(200)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `view_users_x_centers`
--
DROP VIEW IF EXISTS `view_users_x_centers`;
CREATE TABLE `view_users_x_centers` (
`user_id` varchar(20)
,`user_name` varchar(200)
,`center_id` varchar(20)
,`center_name` varchar(200)
);

-- --------------------------------------------------------

--
-- Estructura para la vista `view_users`
--
DROP TABLE IF EXISTS `view_users`;

CREATE ALGORITHM=UNDEFINED DEFINER=`diego_torres`@`localhost` SQL SECURITY DEFINER VIEW `view_users`  AS  select `users`.`user_id` AS `id`,`users`.`user_status` AS `estado`,`users`.`user_name` AS `nombre` from `users` where (`users`.`purged` = 0) order by `users`.`user_name` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `view_users_x_centers`
--
DROP TABLE IF EXISTS `view_users_x_centers`;

CREATE ALGORITHM=UNDEFINED DEFINER=`diego_torres`@`localhost` SQL SECURITY DEFINER VIEW `view_users_x_centers`  AS  select `users`.`user_id` AS `user_id`,`users`.`user_name` AS `user_name`,`centers`.`center_id` AS `center_id`,`centers`.`center_name` AS `center_name` from ((`users` join `centers`) join `users_x_centers`) where ((`users`.`user_id` = `users_x_centers`.`users_x_centers_user_id`) and (`users_x_centers`.`users_x_centers_center_id` = `centers`.`center_id`) and (`users`.`purged` = 0)) order by `users`.`user_name`,`centers`.`center_name` ;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `centers`
--
ALTER TABLE `centers`
  ADD PRIMARY KEY (`center_id`);

--
-- Indices de la tabla `logins`
--
ALTER TABLE `logins`
  ADD PRIMARY KEY (`login_user_id`,`login_time`),
  ADD UNIQUE KEY `login_id_UNIQUE` (`login_id`);

--
-- Indices de la tabla `testing`
--
ALTER TABLE `testing`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `user_mail_UNIQUE` (`user_mail`),
  ADD UNIQUE KEY `user_documen_UNIQUE` (`user_document`);

--
-- Indices de la tabla `users_x_centers`
--
ALTER TABLE `users_x_centers`
  ADD PRIMARY KEY (`users_x_centers_user_id`,`users_x_centers_center_id`),
  ADD KEY `fk_center_id_idx` (`users_x_centers_center_id`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `logins`
--
ALTER TABLE `logins`
  MODIFY `login_id` bigint(20) UNSIGNED ZEROFILL NOT NULL AUTO_INCREMENT COMMENT 'Un indice de secuencia que ayuda a indexar la tabla y a las busquedas de una sesion en particular', AUTO_INCREMENT=95;
--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `users_x_centers`
--
ALTER TABLE `users_x_centers`
  ADD CONSTRAINT `fk_center_id` FOREIGN KEY (`users_x_centers_center_id`) REFERENCES `centers` (`center_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_user_id` FOREIGN KEY (`users_x_centers_user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;