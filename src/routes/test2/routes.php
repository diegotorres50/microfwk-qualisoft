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
        $app->get('/getconfig', function ($request, $response, $args) {

            return $response->withJson($this->general_config, 201);

        });        

    });

});
