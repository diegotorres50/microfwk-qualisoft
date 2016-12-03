<?php
// Routes

$app->get('/test1[/{value}]', function ($request, $response, $args) {
    // Sample log message
    $this->logger->info("Test 1 '/' route");

    $fakeService = new \FakeClass($args['value']);

    $other = $fakeService->fakeMethod();
	
	$data = array('name' => 'Rob', 'age' => 40, 'other' => $other);
	$newResponse = $response->withJson($data, 201);

	return $newResponse;

});

$app->get('/test2[/{name}]', function ($request, $response, $args) {
    // Sample log message
    $this->logger->info("Test 2 '/' route");

    // Render index view
    return $this->renderer->render($response, 'index.phtml', $args);
});

$app->get('/test3[/{value}]', '\TestController:method1');
