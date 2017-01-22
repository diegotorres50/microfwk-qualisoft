<?php
// Application middleware

// e.g: $app->add(new \Slim\Csrf\Guard);

//En los headers del request hay que autenticar: Authorization:Basic base64_encode("hba_username:hba_password")
$app->add(new \Slim\Middleware\HttpBasicAuthentication([
    //"realm" => "Protected",
    "secure" => false,
    //Estos usuarios salen de .htpasswd
    "users" => [
        getenv('hba_username') => getenv('hba_password'),
    ],
    "error" => function ($request, $response, $arguments) {
        $data = [];
        $data["status"] = "error";
        $data["message"] = $arguments["message"];
        $data["all"] = $arguments;
        $data["user"] = getenv('hba_username');
        $data["pass"] = getenv('hba_password');
        $data["encode"] = base64_encode(getenv('hba_username') . ':' . getenv('hba_password'));
        $data["request"] = $request;
        $data["response"] = $response;
        return $response->write(json_encode($data, JSON_UNESCAPED_SLASHES));
    }
]));
