<?php

class JoshcamMysqli
{

    public function __construct($params = [])
    {
        // db staying private here
        $db = new MysqliDb($params['mysql_server'], $params['mysql_user'], $params['mysql_password'], $params['mysql_database']);
    }

    public function getInstance()
    {
        // obtain db object created in init  ()
        $db = MysqliDb::getInstance();

        return $db;
    }
}
