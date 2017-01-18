<?php

use \Interop\Container\ContainerInterface as ContainerInterface;

class AuthController
{
    protected $ci;

    //Constructor
    public function __construct(ContainerInterface $ci)
    {
        $this->ci = $ci;
    }

    public function login($request, $response, $args)
    {

        $feedback = array();

        $params = array();

        $entry = array();

        try {
            //Parametros por get query string
            $queryParams = $request->getQueryParams();

            //Parametros por body (post)
            $bodyParams = $request->getParsedBody();

            $feedback['entry'] = array_merge($queryParams, $bodyParams);

            if (array_key_exists('username', $bodyParams) &&
              !empty($bodyParams['username']) &&
              !is_null($bodyParams['username'])) {
                $params['username'] = $bodyParams['username'];
            } else {
                throw new Exception("usename no esta definido");
            }

            if (array_key_exists('password', $bodyParams) &&
              !empty($bodyParams['password']) &&
              !is_null($bodyParams['password'])) {
                $params['password'] = $bodyParams['password'];
            } else {
                throw new Exception("password no esta definido");
            }

            //Obtenemos la dependencia de conexion mysql para usarla
            $mysqliCli = $this->ci->get('mysqli');

            $authService = new UserAuth($mysqliCli);

            $data = $authService->login($params);

            $feedback['status'] = 1;
            $feedback['code'] = 200;
            $feedback['data'] = $data;
        } catch (Exception $e) {
            $feedback['status'] = 0;
            $feedback['code'] = 400;
            $feedback['data'] = null;
            $feedback['error'] = array();
            $feedback['error']['code'] = $e->getCode();
            $feedback['error']['message'] = $e->getMessage();
            $feedback['error']['line'] = $e->getLine();
            $feedback['error']['file'] = $e->getFile();
            $feedback['error']['method'] = __METHOD__;
            $feedback['error']['trace'] = $e->__toString();
        }

        return $response->withJson($feedback, $feedback['code']);
    }
}
