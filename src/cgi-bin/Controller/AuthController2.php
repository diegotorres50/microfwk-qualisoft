<?php

use \Interop\Container\ContainerInterface as ContainerInterface;
//use Faky\Test\Fake1 as fuckme;
require_once __DIR__ . "/../Model/Test/Fake1.php";

class AuthController {
  protected $ci;
  //Constructor
  public function __construct(ContainerInterface $ci) {
    $this->ci = $ci;
  }
   
  public function login($request, $response, $args) {
    //your code
    //to access items in the container... $this->ci->get('');
	
    //print_r($this->ci->get('env')); die;

    //print_r($args); die;

    //print_r($request->getQueryParams()); die;

    $fakeService = new Fake1($args['api_version']);

    $fakeService = new FakeClass($args['api_version']);

    $other = $fakeService->fakeMethod();

    print_r($other); die;

    print_r($request->getParsedBody()); die;

    //print_r($request->getParsedBodyParam('username', null)); die;

    $data = array('username' => 'diegotorres50', 'password' => '123456', 'api_version' => $args['api_version']);

	  return $response->withJson($data, 201);
   }
}