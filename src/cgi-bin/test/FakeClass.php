<?php
namespace MyProject
;
class FakeClass {

  protected $myVar;

  //Constructor
  public function __construct($param) {
      $this->myVar = $param;
  }
  
  public function fakeMethod() {
    return 'testing: ' . $this->myVar;    
  }
}