<?php

use \Interop\Container\ContainerInterface as ContainerInterface;

class TestController {
   protected $ci;
   //Constructor
   public function __construct(ContainerInterface $ci) {
       $this->ci = $ci;
   }
   
   public function method1($request, $response, $args) {
    //your code
    //to access items in the container... $this->ci->get('');
	
	$data = array('nombre' => 'Diego', 'edad' => 36, 'other' => $args['value']);

	return $response->withJson($data, 201);

   }
   
   public function method2($request, $response, $args) {
        //your code
        //to access items in the container... $this->ci->get('');
   }
      
   public function method3($request, $response, $args) {
        //your code
        //to access items in the container... $this->ci->get('');
   }
}