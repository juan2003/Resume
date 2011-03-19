<?php /* 
Juan Boyce
03/26/2010
table xi algorithm test */

//Constants
define('LINE_ITEM_TEMPLATE',"%3d x [\$%6.2f] %20s: \$%7.2f\n");
define('TOTAL_TEMPLATE','%36s: $%7.2f');

//Use primes to calc greatest common factor 
$primes = array(2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71);

//Get value as float from string
function _v( $str ) { return (float) substr($str,1); }

//Subset sum
function subsum($menu, $target) {
 //Parse exit conditions
 foreach($menu as $idx=>$item) {
  //List is sorted ascending, break when target less than item price
  if($item['intkey'] > $target) break;
  //Shortcut reduces recursive steps, but requires int types, hence intkey
  if($target % $item['intkey'] == 0) return array($idx=>($target / $item['intkey'] ));
 }
 //No exit found, now recurse
 foreach($menu as $idx=>$item) {
  if( $order=subsum($menu, $target-$item['intkey']) ){
   $order[$idx]++;
   return $order;
  }
 }
 return false;
}

//Output function
function pretty($order,$menu) {
 $total = 0;
 $output = '';
 foreach($order as $item=>$qty) {
  $output.=sprintf(LINE_ITEM_TEMPLATE,$qty,$menu[$item]['price'],$menu[$item]['name'],$menu[$item]['price']*$qty);
  $total+=$menu[$item]['price']*$qty;
 }
 $output.=sprintf(TOTAL_TEMPLATE,'Total',$total);
 return $output;
}

//Init
if ($argc < 2) die ('filename not specified');
$file = $argv[1];
if ( file_exists($file) ){
 $data = explode("\n",file_get_contents($file));
} else {
 die( "file \"$file\" not found" );
}

$menu = array();
$name = array();
$price = array();
$keys = array();
$target = _v(array_shift($data));

foreach( $data as $line ) {
 $items = explode(',',$line);
 if( count($items) == 2 ) {
 $name[]=$items[0];
 $price[]=_v($items[1]);
 $keys[] = (int)(_v($items[1])*100);
 }
}

//Calc greatest common factor
$gcf=1;
do {
 foreach($keys as $num){
  foreach($primes as $i=>$prime) {
   if($num < $prime || $num % $prime != 0) unset($primes[$i]);
  }
 }
 foreach($primes as $prime){
  foreach($keys as $i=>$num){
   $keys[$i]=$num/$prime;
  }
  $gcf*=$prime;
 }
} while($primes);

//Sort the arrays
array_multisort($price,SORT_NUMERIC,$name,$keys);

//create the menu
foreach( $price as $i=>$value ) {
 $menu[] = array('name'=>$name[$i],'price'=>$price[$i],'intkey'=>$keys[$i]);
}

//Integer version of target
$int_target = (int) ($target*100);
if ($int_target % $gcf == 0 && $result = subsum($menu,$int_target/$gcf))
 echo pretty($result,$menu);
else echo 'Can\'t do it';
?>

