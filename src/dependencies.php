<?php
// DIC configuration

$container = $app->getContainer();

// view renderer
$container['renderer'] = function ($c) {
    $settings = $c->get('settings')['renderer'];
    return new Slim\Views\PhpRenderer($settings['template_path']);
};

// monolog
$container['logger'] = function ($c) {
    $settings = $c->get('settings')['logger'];
    $logger = new Monolog\Logger($settings['name']);
    $logger->pushProcessor(new Monolog\Processor\UidProcessor());
    $logger->pushHandler(new Monolog\Handler\StreamHandler($settings['path'], $settings['level']));
    return $logger;
};

// environment (inyectamos el alias de entorno de desarrollo)
$container['env'] = function ($c) {
    $settings = $c->get('settings')['env']['environment'];
    return (isset($settings) && !empty($settings) && !is_null($settings)) ? $settings : 'development';
};

// general config
$container['general_config'] = function ($c) {
    $settings = $c->get('settings')['env']['environment'];
    $env = (isset($settings) && !empty($settings) && !is_null($settings)) ? $settings : 'development';
    $files = glob(__DIR__ . '/../config' . '/{global,' . $env . '}/*.php', GLOB_BRACE);
    $config = \Zend\Config\Factory::fromFiles($files);
    return $config;
};

// joshcamMysqli, obtiene una instancia del cliente que se conecta con mysql
$container['mysqli'] = function ($c) {
    //Usando el inyector de dependencias obtenemos los datos de conexion mysql desde el config
    $mysqlConfig = $c->get('general_config')['config']['db']['mysqli'];
    //Preparamos el array de parametros con los datos de conexion
    $params = [];
    $params['mysql_server'] = $mysqlConfig['mysql_server'];
    $params['mysql_user'] = $mysqlConfig['mysql_user'];
    $params['mysql_password'] = $mysqlConfig['mysql_password'];
    $params['mysql_database'] = $mysqlConfig['mysql_database'];
    //Retornamos la instancia
    return new JoshcamMysqli($params);
};
