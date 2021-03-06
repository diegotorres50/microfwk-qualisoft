<?php
// Routes

// API group
$app->group('/api', function () use ($app) {

    // Library group
    $app->group('/library', function () use ($app) {

        // Get book with ID
        $app->get('/book[/{value}]', function ($request, $response, $args) {

            $data = array('name' => 'Andres', 'name2' => 'Campuzano');
            $newResponse = $response->withJson($data, 201);

            return $newResponse;

        });

        // Prueba con inyeccion de dependencias
        $app->get('/getgeneralconfig', function ($request, $response, $args) {

            return $response->withJson($this->general_config, 201);

        });

        // Prueba con variables de entorno
        $app->get('/getenv', function ($request, $response, $args) {

            return $response->withJson($this->env, 201);

        });

        // Prueba con variables de entorno
        $app->get('/getcredentials', function ($request, $response, $args) {

            return $response->withJson($this->http_basic_auth, 201);

        });

    });

});
