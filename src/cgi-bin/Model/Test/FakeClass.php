<?php

class FakeClass {

  protected $myVar;

  //Constructor
  public function __construct($param) {
      $this->myVar = $param;
  }
  
  public function fakeMethod() {

  	$db = new MysqliDb ('localhost', 'root', 'Colombia2006', 'qualisoft_dev');

  	print_r($db); die;

    return 'testing: ' . $this->myVar;    
  }
}