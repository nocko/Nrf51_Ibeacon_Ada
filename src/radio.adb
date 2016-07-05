with Interfaces;
with Ibeacon;
with nrf51; use nrf51;
with nrf51.CLOCK;
with nrf51.GPIO;
with nrf51.Interrupts;
with nrf51.RADIO;
with System.Storage_Elements;

package body Radio is
   use Interfaces;
   Ble_Access_Address : constant Unsigned_32 := 16#8E89_BED6#;

   Packet : Ibeacon.Ibeacon_Packet;

   subtype Channel_Number is UInt7 range 0 .. 39;
   --  subtype Data_Channel_Number is Channel_Number range 0 .. 36;
   subtype Advertising_Channel_Number is Channel_Number range 37 .. 39;
   subtype Adv_Channel_Index is Integer range 1 .. 3;
   --  type Data_Channel_Index is new Integer range 1 .. 37;

   --  nRF51 Radio Peripheral represents frequncy as 2400 + Ble_Frequency
   subtype Ble_Frequency is UInt7 range 2 .. 80;

   --  type Data_Channel is
   --     record
   --        Channel : Data_Channel_Number;
   --        Frequency : Ble_Frequency;
   --     end record;

   type Advertising_Channel is
      record
         Channel : Advertising_Channel_Number;
         Frequency : Ble_Frequency;
      end record;

   Advertising_Channels : constant
     array (1 .. 3) of Advertising_Channel := ((37, 2),
                                               (38, 26),
                                               (39, 80));
   Current_Adv_Channel_Index : Adv_Channel_Index := 1;

   --  Private Functions
   procedure Send;
   procedure RADIO_IRQHandler;
   pragma Export (C, RADIO_IRQHandler, "RADIO_IRQHandler");
   procedure POWER_CLOCK_IRQHandler;
   pragma Export (C, POWER_CLOCK_IRQHandler, "POWER_CLOCK_IRQHandler");

   procedure Init is
      use nrf51.RADIO;
      RADIO : RADIO_Peripheral renames RADIO_Periph;
   begin
      RADIO.MODE.MODE := Ble_1Mbit;
      RADIO.TXPOWER.TXPOWER := TXPOWER_Field_0DBm;
      RADIO.TXADDRESS.TXADDRESS := 0;
      RADIO.PREFIX0.Val := Shift_Right (Ble_Access_Address, 24);
      RADIO.BASE0 := Shift_Left (Ble_Access_Address, 8);

      --  NRF_RADIO->PREFIX0 = ((ACCESS_ADDRESS>>24)
      --    & RADIO_PREFIX0_AP0_Msk);
      --  NRF_RADIO->BASE0 = (ACCESS_ADDRESS<<8);
      RADIO.RXADDRESSES.ADDR.Val := 0;
      RADIO.PCNF0.LFLEN := 8;
      RADIO.PCNF0.S0LEN := 1;
      RADIO.PCNF1.WHITEEN := Enabled;
      RADIO.PCNF1.MAXLEN := 16#ff#;
      RADIO.PCNF1.BALEN := 3;
      RADIO.CRCCNF.LEN := Three;
      RADIO.CRCCNF.SKIPADDR := Skip;
      RADIO.CRCINIT.CRCINIT := 16#0055_5555#;
      --  NRF_RADIO->CRCPOLY = 0x0100065BUL;
      --  Weirdness w/ 24th bit; look here for problems
      RADIO.CRCPOLY.CRCPOLY := 16#0000_065B#;
      RADIO.SHORTS.READY_START := Enabled;
      RADIO.SHORTS.END_DISABLE := Enabled;

      --  Fire interrupt when radio is disabled, happens
      --  automatically when transmission finished thanks to SHORTS
      RADIO.INTENSET.DISABLED := Set;

      --  We also need to configure the clock peripheral to let us
      --  know when the HFCLK has started
      declare
         use nrf51.CLOCK;
         CLOCK : CLOCK_Peripheral renames
           nrf51.CLOCK.CLOCK_Periph;
      begin
         CLOCK.INTENSET.HFCLKSTARTED := Set;
      end;

      declare
         use nrf51.Interrupts;
      begin
         --  Set_Priority (RADIO_IRQ, IRQ_Prio_High);
         Enable (RADIO_IRQ);
         --  Set_Priority (POWER_CLOCK_IRQ, IRQ_Prio_High);
         Enable (POWER_CLOCK_IRQ);
      end;
   end Init;

   procedure Start is
      --  Procedure starts the sending process by priming the HFCLK
      use nrf51.CLOCK;
      CLOCK : CLOCK_Peripheral renames
        nrf51.CLOCK.CLOCK_Periph;
   begin
      CLOCK.TASKS_HFCLKSTART := 1;
   end Start;

   procedure RADIO_IRQHandler is
      use nrf51.RADIO;
      use nrf51.CLOCK;
      use nrf51.GPIO;
      RADIO : RADIO_Peripheral renames RADIO_Periph;
      CLOCK : CLOCK_Peripheral renames CLOCK_Periph;
      GPIO : GPIO_Peripheral renames GPIO_Periph;
   begin
      if RADIO.EVENTS_DISABLED /= 0 then
         RADIO.EVENTS_DISABLED := 0;
         CLOCK.TASKS_HFCLKSTOP := 1;
         if Current_Adv_Channel_Index + 1 not in Adv_Channel_Index'Range then
            Current_Adv_Channel_Index := 1;
         else
            Current_Adv_Channel_Index := Current_Adv_Channel_Index + 1;
         end if;
         GPIO.OUTSET.Arr (12) := Set;
      end if;
   end RADIO_IRQHandler;

   procedure POWER_CLOCK_IRQHandler is
      use nrf51.CLOCK;
      CLOCK : CLOCK_Peripheral renames
        nrf51.CLOCK.CLOCK_Periph;
   begin
      if CLOCK.EVENTS_HFCLKSTARTED /= 0 then
         CLOCK.EVENTS_HFCLKSTARTED := 0;
         Send;
      end if;
   end POWER_CLOCK_IRQHandler;

   procedure Send is
      use nrf51.RADIO;
      use Ibeacon;
      RADIO : RADIO_Peripheral renames RADIO_Periph;
      I : Adv_Channel_Index renames Current_Adv_Channel_Index;
   begin
      RADIO.PACKETPTR := Unsigned_32 (
        System.Storage_Elements.To_Integer (Packet'Address));
      RADIO.FREQUENCY.FREQUENCY := Advertising_Channels (I).Frequency;
      RADIO.DATAWHITEIV.DATAWHITEIV := Advertising_Channels (I).Channel;
      RADIO.EVENTS_END := 0;
      RADIO.TASKS_TXEN := 1;
   end Send;
end Radio;
