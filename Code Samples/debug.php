<?php
/* Debug.php Juan Boyce 03/01/2010
This includes Debug functions automagically
remove to disable */

/**
* This class shows the method calls to the PHP object.
*
* @package default
* @author Juan Boyce
*/
class Debug {
	/**
	* The value to return when a method is called
	*
	* @var string
	*/
	public $return_value = false;

	/**
	* The number of times to run before quitting use null to disable
	*
	* @var string
	*/
	public $max_call = 150;

	/**
	* internal call counter
	*
	* @var string
	*/
	private $call_count = 0;
	private $verbose = false;
	private $passthru = null;
	private $name = 'Debug';

	/**
	* This array holds the content of the source files
	*
	* @author Juan Boyce
	*/
	private static $files = array();

	/**
	* This catches all method calls and outputs data to the console
	*
	* @param string $name
	* @param string $args
	* @return void
	* @author Juan Boyce
	*/
	public function __call($name, $args) {
		$names = $this->getArglist();
		//create an array for the named arguments
		$arguments = null;
		foreach( $args as $arg ){
			$key = trim(current($names));
			while( isset($arguments[$key]) ){
				$key .= chr(0); // Nul is invisible, but makes the key unique so that we can have seemingly duplicate keys
			}
			$arguments[$key] = $arg;
			next($names);
		}
		$this->log('method call',compact('name','arguments'));
		if($passthru) {
			$this->log('method return',call_user_func_array(array($passthru,$name),$args));
		}
		if( $call_count++ > $this->max_call ){
			$this->terminate('Max calls reached');
		}
		return $this->return_value;
	}
	
	private function log($event, $detail=null, $terminate=null ) {
		$time = time();
		$name = $this->name;
		self::$global_runtime_data[]=compact('time','name','event','detail');
		if($this->verbose) {
			self::output(compact('name','time','event','detail'));
		}
		if($terminate) {
			$this->terminate($terminate);
		}
	}
	
	private function terminate($reason) {
		$this->log('terminate',$reason);
		if(!$verbose){
			self::output(self::$global_runtime_data);
		}
		exit;
	}

	/**
	* Returns an array of parameters passed to function used for labels
	*
	* @return void
	* @author Juan Boyce
	*/
	private function getArglist() {
		$trace = debug_backtrace(false);
		$line = $trace[2]['line']-1;
		$file = $trace[2]['file'];
		$func = $trace[2]['function'];
		if (!isset(self::$files[$file])){
			self::$files[$file] = file($file);
		}
		$subject = self::$files[$file][$line];
		if( preg_match( "/$func\\s*\\((.*)\\)/i",$subject,$matches) ){
			return explode(',',$matches[1]);
		}
		return null;
	}

	public function __construct($name, Object $obj = null) {
		$this->name = $name;
		$this->passthru = $obj;
	}
	
	public static $global_verbose = false;
	public static $global_runtime_data = null;
	private static function output($data) {
		if(self::$global_verbose) {
			echo '<pre>'.print_r($data,true).'</pre>';
		}
	}
	public static function global_log($event, $detail=null) {
		$time = time();
		self::$global_runtime_data[]=compact('time','event','detail');
		if(self::$global_verbose) {
			self::output(compact('time','event','detail'));
		}
	}
}

function debug_print() {
	Debug::global_log('session',$_SESSION);
	echo '<pre>', print_r(Debug::$global_runtime_data,true);
	var_dump($_SESSION);
	if(isset($cart)) var_dump($cart);
	if(isset($error_msg)) var_dump($error_msg);
	echo '</pre>';
}

//Dummy functions for cURL
function curl_init() {
	return null;
}
function curl_setopt(&$a,$b,$c) {
	$a[$b]=$c;
}
function curl_exec(&$a) {
	Debug::global_log('curl_exec',$a);
	return null;
}
function curl_getinfo(&$a) {
	return null;
}
function curl_close (&$a) {
	unset($a);
}
function curl_errno($a) {
	return null;
}

?>