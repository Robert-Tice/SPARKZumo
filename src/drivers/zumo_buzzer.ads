--pragma SPARK_Mode;

with Types; use Types;

--  @summary
--  Interface to the robot's buzzer
--
--  @description
--  This is not totally implemented yet. DO NOT USE!!
--
package Zumo_Buzzer is

   --  True if the interface is init'd
   Initd : Boolean := False;

   --  Init the interface
   procedure Init
     with Pre => not Initd,
     Post => Initd;

   --  Play a note at a frequency
   --  @param Freq the frequency to play
   --  @param Dur the duration to the play the note
   --  @param Vol the volume to play the note
   procedure PlayFrequency (Freq : Frequency;
                            Dur : Duration;
                            Vol   : Volume)
     with Pre => Initd;

   --  Play a specific note
   --  @param Note which note to play
   --  @param Dur the duration of the note to play
   --  @param Vol the volume of the note to play
   procedure PlayNote (Note : Integer;
                       Dur : Duration;
                       Vol   : Volume)
     with Pre => Initd;

   function PlayCheck return Boolean;

   --  Am I currently playing a note?
   --  @return true if I am playing a note
   function IsPlaying return Boolean;

   --  Enough already! Stop playing loud annoying noises.
   procedure StopPlaying;



end Zumo_Buzzer;
