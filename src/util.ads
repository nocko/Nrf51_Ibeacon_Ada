package Util is
   procedure Delay_Init;
   procedure Delay_MS (Milliseconds : Natural);
   procedure WFI;
private
   Delay_Active : Boolean := False;
end Util;
