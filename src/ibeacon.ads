with Interfaces;

package Ibeacon is
   use Interfaces;
   type Mac_Type is array (0 .. 5) of Unsigned_8;
   type Apu_Header_Type is array (0 .. 1) of Unsigned_8;
   type Manuf_Data_Header is array (0 .. 3) of Unsigned_8;
   type UUID_Type is array (0 .. 15) of Unsigned_8;
   type Ibeacon_Packet is
      record
         Header : Unsigned_8 := 16#42#;
         Radio_Length : Unsigned_8 := 16#24#;
         Mac : Mac_Type := (16#FE#, 16#CA#, 16#EF#,
                           16#BE#, 16#AD#, 16#DE#);
         Flags_Length : Unsigned_8 := 2;
         Flags_Type : Unsigned_8 := 1;
         Flags_Content : Unsigned_8 := 6;
         Data_Length : Unsigned_8 := 16#1A#;
         Data_Type : Unsigned_8 := 16#FF#; --  Manuf. Spec Data
         Data_Header : Manuf_Data_Header :=
           (16#4C#, 16#00#, 16#02#, 16#15#);
         UUID : UUID_Type := (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12,
                              13, 14, 15, 16);
         Major : Unsigned_16 := 0;
         Minor : Unsigned_16 := 0;
         Power : Integer_8 := -70;
      end record;

end Ibeacon;
