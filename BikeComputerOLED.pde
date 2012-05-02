// Bike computer by Chris Purola

#include<stdlib.h>


//circ circumference in millimeters
int circ = 2108;

//Serial LCD is on standard Arduino tx/rx pin
byte SensorPin = 2;                     //Input pin for speed sensor
unsigned long tripTime;                 //last time sensor was tripped
unsigned long lastTripTime;             //time before last sensor was tripped
unsigned long revs = 0;                 //number of revs
unsigned int milsecs;                   //this will overflow after 64 seconds or so between hits, but that doesn't matter, only need it for sub-second timings
unsigned int outspeed;                  //speed output to screen
unsigned long totalmm;                  //total millimeters
float mph = 0;                          //current calculated speed
unsigned int avg[4];                    //array for averaging speed
volatile boolean state = false;         //check for if sensor has been tripped
byte menuPin = 3;                       //Menu button
unsigned long menuTrip;                 //last trip time for menu button
boolean menuState;                      //current state of menu button
byte menuSelect;                        //current display mode
unsigned long displayTimer;             //last screen update
char diststring[10];


void setup()
{
  pinMode (SensorPin,INPUT);            //enable input sensor
  pinMode (menuPin,INPUT);
  digitalWrite (SensorPin, HIGH);       //turn on pull up resistor
  digitalWrite (menuPin, HIGH);

  Serial.begin(19200);                   //Code for setting LCD to 38400 baud. LCD stores speed in EEPROM, so reconfig shouldn't be necessary.
  Disp_Init();
 // Serial.print(124, BYTE);
 // Serial.print(16, BYTE);
  delay(500);

 // Serial.begin(38400);                  //Start serial communications with LCD
 // Serial.print(0xFE, BYTE);             //Command byte
 // Serial.print(0x01, BYTE);             //Clear screen
   Disp_Clear();
  attachInterrupt(0,sense,LOW);         //Setup interrupt for wheel sensor
  Disp_SetTrans(1);                        //Set so that updates to text won't require redraws of that whole area, makes text updates flicker-free
}


void loop()
{
  if(state == true && (millis() - tripTime) > 40)    //check if the thing's been tripped, and also debounce the input (40ms = approx 250mph).
  {
    tripTime = millis();                //set the time the interrupt occured
    revs = revs + 1;                    //update the revs number
    calc();                             //recalculate the current stats
  }

  if(state == true)                     //if it's still true...
    state = false;                      //falsify state
    
  if (digitalRead(menuPin) == LOW)      //If the button is currently pushed
   {
    if ((menuState == false) && ((millis() - menuTrip) > 250))  //Check to see if the button was previously not pushed -If it was held- and if it's been longer than 250ms since last trip -For debounce-
    {
      menuState = true;                 //Set the current state to pressed
      menuTrip = millis();              //Reset the tripped time
      menuchange();                     //call the menu change routine
    }
   }
  else if (digitalRead(menuPin) == HIGH)  //If the button is not pushed
  {
    menuState = false;                  //Set the state to released
  }
//ScootArea(1,1,0,0,160,50);
}



void menuchange()
{
  menuSelect++;                         //Advance the menu and roll it over if need be
  if (menuSelect == 2)
    menuSelect = 0;
  display();                            //Update the display to give feedback that pressing the button does something
}


void calc() 
{
  digitalWrite(13, HIGH);
  milsecs = tripTime - lastTripTime;    //calculate the difference between the current time and the last tripped time
  lastTripTime = tripTime;              //reset the last tripped time
  mph = (circ / milsecs) * 2.2369;      //calculate the speed
  avg[0] = avg[1];                      //shift storage array
  avg[1] = avg[2];                      //    "
  avg[2] = avg[3];                      //    "
  avg[3] = int(mph);                    //insert current calculated mph
  if ((millis() - displayTimer) >= 500) //run the display routine every 500ms if the wheel is spinning
    {
      displayTimer = millis();
      display();
    }
    digitalWrite(13, LOW);
}

void display()
{
 // Disp_DrawRect(0,0,160,50,1,00000);
  totalmm = revs * circ;                //multiply the number of revs by circumference to get total mm
  outspeed = ((avg[0] + avg[1] + avg[2] + avg[3]) / 4);    //average the speed over the last four readings (mean)
  Disp_DrawString("Dist:",0,0,2,2,2,65535);
 // Serial.print(0xFE, BYTE);             //Command byte
 // Serial.print(0x01, BYTE);             //Clear screen
 // Serial.print("Dist: ");               //Show distance
  if (menuSelect == 0)
  {
    float dist1 = totalmm / 1609344.0;  //in miles
  //dtostrf(FLOAT,WIDTH,PRECISION,BUFFER)
    dtostrf(dist1,0,2,diststring);
    Disp_DrawString(diststring,90,0,2,2,2,65535);
  //  Serial.print(dist1);                //""
  //  Serial.print(" mi");                //show denominator
  }
  else if (menuSelect == 1)
  {
    unsigned long dist1 = totalmm / 304.8;      //in feet
  //  Serial.print(dist1);                //""
  //  Serial.print(" ft");                //show denominator
  }
  //Serial.print(0xFE, BYTE);             //Command byte
  //Serial.print(192, BYTE);              //Move to 2nd line
  Disp_DrawString("Speed:",0,25,2,2,2,65535);
  dtostrf(outspeed,0,0,diststring);
  Disp_DrawString(diststring,110,25,2,2,2,65535);
  //Serial.print("Speed: ");              //Show speed
  //Serial.print(outspeed);               //   "
  //Serial.print(" mph");                 //show denominator
}


void sense()
{
  state = true;
}


/*************************************

OLED Driver for uOLED96/128/160-G1 Serial device

By Chris Purola
Derived from oled160drv.h by Oscar Gonzalez

*************************************/

// This driver does not use responses from the display in any useful way.
// It merely uses it as a signal to send the next instruction. If you need
// to have the responses of ACK/NACK processed by your application, you
// should insert code in GetResponse to respond using incomingByte's output.



void Disp_GetResponse()            //get response from OLED control. We don't really care if it's ACK or NACK, the results should be visible on the screen if the command is working or not.
{
  while (!Serial.available()) { delay(1); }  //while there is nothing to read, wait 1ms and retry (wait for the OLED uC to send back a response)
  byte incomingByte = Serial.read();  //read the byte in
}

void SendColor(byte r, byte g, byte b)
{
  byte smr
  byte smg
  byte smb
  smr = r >> 3
  smg = g >> 2
  smb = b >> 3
  
  

void Disp_Init()
{
  delay(1000);                      //wait for init
  Serial.print(0x55,BYTE);          //send auto baudrate lock byte (U)
  Disp_GetResponse();
  delay (50);                       //GOLDELOX uC seems to freak out a bit if we don't wait a little after autobaud before sending it commands. 50ms seems to do the trick.
}

void Disp_PwrCtl(byte pwr)
{
  Serial.print(0x59,BYTE);
  Serial.print(0x03,BYTE);
  Serial.print(pwr,BYTE);         //send byte to turn on (1) or off (0)
  Disp_GetResponse();
}

void Disp_Clear()
{
  Serial.print(0x45,BYTE);          //send clear byte
  delay(20);
  Disp_GetResponse();
}

void Disp_SetBG(int color)
{
  Serial.print(0x42,BYTE);          //send BG set command
  Serial.print(color >> 8,BYTE);    //send color MSB
  Serial.print(color & 0xFF,BYTE);  //send color LSB
  Disp_GetResponse();
}

void ScootArea(byte x1, byte y1, byte w, byte h, byte x2, byte y2)
{
  Serial.print(0x63,BYTE);
  Serial.print(x1,BYTE);
  Serial.print(y1,BYTE);
  Serial.print(x2,BYTE);
  Serial.print(y2,BYTE);
  Serial.print(w,BYTE);
  Serial.print(h,BYTE);
  Disp_GetResponse();
}
  
void Disp_PutPixel(byte x, byte y, int color)
{
  Serial.print(0x50,BYTE);          //send put pixel
  Serial.print(x,BYTE);             //send x
  Serial.print(y,BYTE);             //send y
  Serial.print(color >> 8,BYTE);    //send color MSB
  Serial.print(color & 0xFF,BYTE);  //send color LSB
  Disp_GetResponse();
}

void Disp_DrawLine(byte x1, byte y1, byte x2, byte y2, int color)
{
  Serial.print(0x4C,BYTE);          //send Drawline
  Serial.print(x1,BYTE);            //send x1
  Serial.print(y1,BYTE);            //send y1
  Serial.print(x2,BYTE);            //send x2
  Serial.print(y2,BYTE);            //send y2
  Serial.print(color >> 8,BYTE);    //send color MSB
  Serial.print(color & 0xFF,BYTE);  //send color LSB
  Disp_GetResponse();
}

void Disp_DrawTriangle(byte x1, byte y1, byte x2, byte y2, byte x3, byte y3, int filled, int color)
{                                   //vertices need to be specified in a counter-clockwise manner. x1/y1/x2/y2/x3/y3, going in a counter-clockwise direction through each point
  if (filled == 1)                  //if the triangle should be filled, set it
    Disp_SetFill(1);
  else
    Disp_SetFill(0);
  Serial.print(0x47,BYTE);          //send DrawTriangle
  Serial.print(x1,BYTE);            //send x1
  Serial.print(y1,BYTE);            //send y1
  Serial.print(x2,BYTE);            //send x2
  Serial.print(y2,BYTE);            //send y2
  Serial.print(x3,BYTE);            //send x3
  Serial.print(y3,BYTE);            //send y3
  Serial.print(color >> 8,BYTE);    //send color MSB
  Serial.print(color & 0xFF,BYTE);  //send color LSB
  Disp_GetResponse();
}

void Disp_DrawRect(byte x, byte y, byte wide, byte high, int filled, int color)
{
  if (filled == 1)                  //if the rectangle should be filled, set it
    Disp_SetFill(1);
  else
    Disp_SetFill(0);
  Serial.print(0x72,BYTE);          //send DrawRectangle
  Serial.print(x,BYTE);             //send x
  Serial.print(y,BYTE);             //send y
  Serial.print(x+wide,BYTE);       //send width
  Serial.print(y+high,BYTE);      //send height
  Serial.print(color >> 8,BYTE);    //send color MSB
  Serial.print(color & 0xFF,BYTE);  //send color LSB
  Disp_GetResponse();
}

void Disp_DrawCircle(byte x, byte y, byte radius, byte filled, int color)
{
  if (filled == 1)                  //if the rectangle should be filled, set it
    Disp_SetFill(1);
  else
    Disp_SetFill(0);
  Serial.print(0x43,BYTE);          //send Circle
  Serial.print(x,BYTE);             //send x
  Serial.print(y,BYTE);             //send y
  Serial.print(radius,BYTE);        //send radius
  Serial.print(color >> 8,BYTE);    //send color MSB
  Serial.print(color & 0xFF,BYTE);  //send color LSB
  Disp_GetResponse();  
}

void Disp_SetFill(byte fill)
{
  Serial.print(0x70,BYTE);          //send Pensize command
  if (fill == 1)
    Serial.print(0x00,BYTE);        //send solid command
  else
    Serial.print(0x01,BYTE);        //send wireframe command
  Disp_GetResponse();
}

void Disp_SetFont(byte font)
{
  Serial.print(0x46,BYTE);
  Serial.print(font,BYTE);
  Disp_GetResponse();
}

void Disp_SetTrans(byte trans)      //set the transparency behind the text. 0 = Transparent, 1 = Opaque (box around text)
{
  Serial.print(0x4F,BYTE);
  Serial.print(trans,BYTE);
  Disp_GetResponse();
}

void Disp_DrawCharText(char letter, byte column, byte row, byte font, int color)    //draw character using row/column spacing. font set by SetFont.
{
  Disp_SetFont(font);
  Serial.print(0x54,BYTE);
  Serial.print(letter,BYTE);
  Serial.print(column,BYTE);
  Serial.print(row,BYTE);
  Serial.print(color >> 8,BYTE);
  Serial.print(color & 0xFF,BYTE);
  Disp_GetResponse();
}

void Disp_DrawChar(char letter, byte x, byte y, byte wide, byte high, byte font, int color)    //draw char with xy and width/height. font set by SetFont.
{
  Disp_SetFont(font);
  Serial.print(0x74,BYTE);            //send drawchar
  Serial.print(letter,BYTE);          //send character
  Serial.print(x,BYTE);
  Serial.print(y,BYTE);
  Serial.print(color >> 8,BYTE);
  Serial.print(color & 0xFF,BYTE);
  Serial.print(wide,BYTE);            //Send width
  Serial.print(high,BYTE);            //send height
  Disp_GetResponse();
}

void Disp_DrawStringText(char text[], byte column, byte row, byte font, int color)
{
  Serial.print(0x73,BYTE);
  Serial.print(column,BYTE);          //column (0-20 for font 0, 0-15 for fonts 1 and 2)
  Serial.print(row,BYTE);             //row (0-15 for fonts 0 and 1, 0-9 for font 2)
  Serial.print(font,BYTE);            //Font (0,1, or 2)
  Serial.print(color >> 8,BYTE);
  Serial.print(color & 0xFF,BYTE);
  byte i = 0;
  while(text[i] != '\0'){             //serially send the array of characters out
    Serial.print(text[i],BYTE);
    i++;
  }
  Serial.print(0x00,BYTE);
  Disp_GetResponse();
}

void Disp_DrawString(char text[], byte x, byte y, byte font, byte wide, byte high, int color)
{
  Serial.print(0x53,BYTE);
  Serial.print(x,BYTE);
  Serial.print(y,BYTE);
  Serial.print(font,BYTE);            //font is 0,1,2
  Serial.print(color >> 8,BYTE);
  Serial.print(color & 0xFF,BYTE);
  Serial.print(wide,BYTE);            //width multiplier
  Serial.print(high,BYTE);            //height multiplier
  byte i = 0;
  while(text[i] != '\0'){
    Serial.print(text[i],BYTE);
    i++;
  }
  Serial.print(0x00,BYTE);
  Disp_GetResponse();
}

void Disp_DrawButton(char text[], byte state, byte x, byte y, byte font, byte wide, byte high, int butcolor, int textcolor)
{
  Serial.print(0x62,BYTE);
  Serial.print(state,BYTE);            //can be 0 for pressed, 1 for not pressed
  Serial.print(x,BYTE);
  Serial.print(y,BYTE);
  Serial.print(butcolor >> 8,BYTE);    //button background color
  Serial.print(butcolor & 0xFF,BYTE);
  Serial.print(font,BYTE);
  Serial.print(textcolor >> 8,BYTE);   //button text color
  Serial.print(textcolor & 0xFF,BYTE);
  Serial.print(wide,BYTE);             //text scale multiplier
  Serial.print(high,BYTE);             //text scale multiplier
  byte i = 0;
  while(text[i] != '\0'){
    Serial.print(text[i],BYTE);
    i++;
  }
  Serial.print(0x00,BYTE);             //terminator byte
  Disp_GetResponse();
}
