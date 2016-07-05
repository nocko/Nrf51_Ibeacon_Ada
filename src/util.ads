with nrf51.RTC;

package Util is
   use nrf51.RTC;
   procedure Delay_Init;
   procedure Delay_MS (Milliseconds : Natural);
   procedure WFI;
private
   Delay_Active : Boolean := False;
end Util;
