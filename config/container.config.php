<?php
return [
    'settings' => [
        'displayErrorDetails' => true, // set to false in production
        'addContentLengthHeader' => false, // Allow the web server to send the content-length header

        // Renderer settings
        'renderer' => [
            'template_path' => __DIR__ . '/../templates/',
        ],

        // Monolog settings
        'logger' => [
            'name' => 'slim-app',
            'path' => __DIR__ . '/../logs/app.log',
            'level' => \Monolog\Logger::DEBUG,
        ],

        // Environment var (todas las variables del archivo .env)
        'env' => [
            'environment' => strtolower(getenv('ENVIRONMENT')),
        ],

        // Environment var (todas las variables del archivo .htpasswd) - http basic authentication credentials (inyectamos las credenciales user/pass)
        'http_basic_auth' => [
            'hba_username' => getenv('hba_username'),
            'hba_password' => getenv('hba_password'),
        ],
    ],
];
