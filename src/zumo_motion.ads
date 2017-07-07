pragma SPARK_Mode;


package Zumo_Motion is  
   
   type Degrees is mod 360;
  
   
   procedure Init;
     
   procedure Get_Position (Roll  : out Degrees;
                           Pitch : out Degrees;
                           Yaw   : out Degrees);
   
   function Get_Heading return Degrees; 
   
   

end Zumo_Motion;
