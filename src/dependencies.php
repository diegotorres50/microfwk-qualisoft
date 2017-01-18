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

// joshcamMysqli
$container['mysqli'] = function ($c) {
    $params = [];
    $params['mysql_server'] = 'localhost';
    $params['mysql_user'] = 'root';
    $params['mysql_password'] = 'Colombia2006';
    $params['mysql_database'] = 'qualisoft_dev';
    return new JoshcamMysqli($params);
};
