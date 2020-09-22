library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;


package sorting is

  subtype type_elems is std_logic_vector(7 downto 0);
  type type_sort is array(natural range<>)(natural range<>) of type_elems ;  -- sorting funtion type
  
  function sort (
    signal inputs : type_sort)          -- inputs in mixed order
    return type_sort;
  
end sorting;

package body sorting is

 -- purpose: sorts the input signal values
 function sort (
   signal inputs : type_sort)           -- inputs in mixed order
   return type_sort is
 begin  -- sort
   
 end sort;

end sorting;
