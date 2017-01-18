<?php

class UserAuth
{

    protected $mysqliClient;
    protected $mysqliInstance;

    //Constructor
    public function __construct(JoshcamMysqli $mysqliCli)
    {

        //aqui el JoshcamMysqli deberia ser una clase custom por si en algun futuro tenemos que cambiar la libreria que conecta con mysqli
        //$this->mysqliClient = new JoshcamMysqli();
        $this->mysqliClient = $mysqliCli;

        $this->mysqliInstance = $this->mysqliClient->getInstance();
    }

    //Metodo para hacer login en mysql
    public function login($params = [])
    {

        try {
            //Esperamos que el array de parametros contenga el username
            if (array_key_exists('username', $params) &&
                !empty($params['username']) &&
                !is_null($params['username'])) {
                $username = $params['username'];
            } else {
                throw new Exception("username no esta definido");
            }

            //Esperamos que el array de parametros contenga el password
            if (array_key_exists('password', $params) &&
                !empty($params['password']) &&
                !is_null($params['password'])) {
                $password = $params['password'];
            } else {
                throw new Exception("password no esta definido");
            }

            //Ejecutamos el procedimiento almacenado de mysql
            $setStoreProcedure = $this->mysqliInstance->rawQuery("call procedure_auth_login(?,?,@_responseCode,@_responseMessage,@_userName);", array($username, $password));

            //Recogemos la respuesta del procedimiento ejecutado
            $data = $this->mysqliInstance->rawQuery("select @_responseCode, @_responseMessage, @_userName;", array());

            if (!is_array($data[0]) || !array_key_exists('@_responseCode', $data[0])) {
                throw new Exception("respuesta mal formada");
            }

            //if (!boolval($data[0]['@_responseCode'])) {
            //  throw new Exception("usuario o contrasenia incorrecta");
            //}

            //Pendiente aqui definir el estandar de respuesta del metodo
        } catch (Exception $ex) {
            //Pendiente aqui para definir como definimos el estandar de respuesta de error, no se si devolver un array o directamente la excepcion y asi mismo saber si voy a responder el http code
            //$data = 'Error: ' . $ex->getMessage();
            throw $ex;
        }

        return $data;
    }
}
