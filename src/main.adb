with SPARKZumo;

procedure main is
begin

   -- DO NOT PUT ANYTHING HERE!!

   -- This forces SPARK-to-C to create an ada init entry point to call from the C main
   SPARKZumo.Setup;
   SPARKZumo.WorkLoop;
end main;
