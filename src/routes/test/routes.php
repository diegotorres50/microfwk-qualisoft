<?php
// Routes

$app->get('/test1[/{value}]', function ($request, $response, $args) {
    // Sample log message
    $this->logger->info("Test 1 '/' route");

    // Render index view
    return "Test: " . $args['value'];
});

$app->get('/test2[/{value}]', function ($request, $response, $args) {
    // Sample log message
    $this->logger->info("Test 2 '/' route");

    // Render index view
    return $this->renderer->render($response, 'index.phtml', $args);
});