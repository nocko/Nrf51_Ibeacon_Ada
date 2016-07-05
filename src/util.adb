with Interfaces;
with System.Machine_Code;
with nrf51;
with nrf51.CLOCK;
with nrf51.Interrupts;
with nrf51.RTC;

package body Util is
   use Interfaces;
   use nrf51;
   RTC_Clock_Freq : constant Integer := 10#32768#;
   Delay_Timer_Prescaler : constant := 0;

   RTC1 : nrf51.RTC.RTC_Peripheral renames nrf51.RTC.RTC1_Periph;
   CLOCK : nrf51.CLOCK.CLOCK_Peripheral renames nrf51.CLOCK.CLOCK_Periph;

   --  Private Functions
   procedure RTC1_IRQHandler;
   pragma Export (C, RTC1_IRQHandler, "RTC1_IRQHandler");

   function MS_To_Ticks (Milliseconds : Natural) return UInt24;

   function MS_To_Ticks (Milliseconds : Natural) return UInt24 is
   begin
      return UInt24 (((Float (RTC_Clock_Freq) /
                         Float (Delay_Timer_Prescaler + 1))
                      / 1000.0) * Float (Milliseconds));
   end MS_To_Ticks;

   procedure Delay_Init is
   begin
      declare
         use nrf51.CLOCK;
      begin
         if CLOCK.EVENTS_LFCLKSTARTED /= 1 then
            CLOCK.LFCLKSRC.SRC := Xtal;
            CLOCK.TASKS_LFCLKSTART := 1;
            loop
               --  Waiting for the LF Oscillator to start
               exit when CLOCK.EVENTS_LFCLKSTARTED = 1;
            end loop;
         end if;
      end;
      declare
         use nrf51.Interrupts;
         use nrf51.RTC;
      begin
         RTC1.PRESCALER.PRESCALER := Delay_Timer_Prescaler;
         RTC1.TASKS_STOP := 1;
         RTC1.TASKS_CLEAR := 1;
         RTC1.INTENSET.COMPARE.Arr (0) := Set;
         --  Interrupts.Set_Priority(RTC1_IRQ, IRQ_Prio_Low);
         Interrupts.Enable (RTC1_IRQ);
      end;
   end Delay_Init;

   procedure WFI is
      use System.Machine_Code;
   begin
      Asm (Template => "wfi", Volatile => True);
      return;
   end WFI;

   procedure Delay_MS (Milliseconds : Natural) is
      use nrf51.RTC;
   begin
      RTC1.CC (0).COMPARE := MS_To_Ticks (Milliseconds);
      Delay_Active := True;
      RTC1.TASKS_START := 1;
      loop
         WFI;
         exit when Delay_Active = False;
      end loop;
   end Delay_MS;

   procedure RTC1_IRQHandler is
   begin
      Delay_Active := False;
      RTC1.TASKS_STOP := 1;
      RTC1.TASKS_CLEAR := 1;
      RTC1.EVENTS_COMPARE (0) := 0;
   end RTC1_IRQHandler;
end Util;
