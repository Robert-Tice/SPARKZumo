--pragma SPARK_Mode;

with Types; use Types;

package Zumo_Buzzer is

   Initd : Boolean := False;

   procedure Init
     with Pre => not Initd,
     Post => Initd;


   procedure PlayFrequency (Freq : Frequency;
                            Dur : Duration;
                            Vol   : Volume)
     with Pre => Initd;

   procedure PlayNote (Note : Integer;
                       Dur : Duration;
                       Vol   : Volume)
     with Pre => Initd;

   function PlayCheck return Boolean;

   function IsPlaying return Boolean;

   procedure StopPlaying;



end Zumo_Buzzer;
