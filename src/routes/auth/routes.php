<?php
// Routes

// User Authentication group
$app->group('/auth', function () use ($app) {
    // Handles multiple HTTP request methods
    $this->map(['GET', 'POST', 'DELETE', 'PATCH', 'PUT', 'OPTIONS'], '')->setName('auth');

    // Get logging in
    $this->post('/login/{api_version}', '\AuthController:login')->setName('auth-login');
});
