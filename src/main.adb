with nrf51.GPIO;
with Util;
with Radio;

procedure Main is
   use nrf51.GPIO;
   use Util;
   GPIO : GPIO_Peripheral renames nrf51.GPIO.GPIO_Periph;
begin
   GPIO.DIRSET.Arr (12) := Set;
   GPIO.OUTSET.Arr (12) := Set;
   Delay_Init;
   Radio.Init;
   loop
      Delay_MS (100);
      Radio.Start;
      GPIO.OUTCLR.Arr (12) := Clear;
      WFI;
   end loop;
end Main;
