#include <DmxSimple.h>

char inData[10];
char inData2[10];
char *result = NULL;
char delims[] = ",";
int index;
int inInt[2];
boolean started = false;
boolean ended = false;
void setup(){
Serial.begin(115200);
}
void loop()
{
   while(Serial.available() > 0)
   {
	 char aChar = Serial.read();
	 if(aChar == '<')
	 {
	     started = true;
	     index = 0;
	     inData[index] = '\0';
	 }
	 else if(aChar == '>')
	 {
	     ended = true;
	 }
	 else if(started)
	 {
	     inData[index] = aChar;
	     index++;
	     inData[index] = '\0';	 
          }
   }
  

   if(started && ended)
   {
	 // Convert the string to an integer
         result = strtok( inData, delims );
         index = 0;
         
         while( result != NULL ) {
              inInt[index] = atoi(result);
              result = strtok( NULL, delims );
              index++;
          }
          
	 // Use the value
         DmxSimple.write(inInt[0], inInt[1]);
         analogWrite(inInt[0], inInt[1]);
	 // Get ready for the next time
	 started = false;
	 ended = false;

	 index = 0;
	 inData[index] = '\0';
  
 }
}
