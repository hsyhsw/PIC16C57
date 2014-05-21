#include <16c57.h>

#define ARRAY_LENGTH (5)

#define write(addr, data) (*(unsigned char *) addr) = data
#define read(addr) (*(unsigned char *) addr)

#define PORTA (0x05)
#define PORTB (0x06)
#define PORTC (0x07)

/*
int main() {
   unsigned char array[ARRAY_LENGTH] = { 35, 2, 15, 5, 20 };

   int i;
   int j;
   int temp;
   
   int arrayLen = 5;
   
   //configure port b as output
#asm
   MOVLW 0x00
   TRIS PORTA
   TRIS PORTB
   TRIS PORTC
#endasm

   //before sort
   for (i = 0; i < arrayLen; i++) {
      write(PORTA, 0x01);
      write(PORTB, array[i]);
      write(PORTA, 0x0F);
   }
   
   for (i = 0; i < arrayLen - 1; i++) {
      for (j = 1; j < arrayLen - i; j++) {
         if (array[j - 1] > array[j]) {
            temp = array[j - 1];
            array[j - 1] = array[j];
            array[j] = temp;
         }
      }
   }

   //after sort
   for (i = 0; i < arrayLen; i++) {
      write(PORTA, 0x01);
      write(PORTB, array[i]);
      write(PORTA, 0x0F);
   }

   return 0;
}
*/

#define SIGNAL_READY (0x1)
#define SIGNAL_BUSY  (0x4)
#define SIGNAL_RESULT (0xF)

int main() {

   //note that sum is 16-bit
   int16 sum = 0;
   int i;
   int8 val1;
   int8 val2;
   
   unsigned char *dat = &sum;
   
   //int arrayLen = 5;
   
#asm
   //configure port a as output
   MOVLW 0x0
   TRIS PORTA
   
   //configure port b, c as input
   MOVLW 0xFF
   TRIS PORTB
   TRIS PORTC
#endasm

   write(PORTA, SIGNAL_READY);

   for (i = 0; i < 5; ++i) {
      write(PORTA, SIGNAL_READY);
      val1 = read(PORTB);
      val2 = read(PORTC);
      write(PORTA, SIGNAL_BUSY);
      
      sum += _mul(val1, val2);
   }
   
   write(PORTA, SIGNAL_RESULT);
   
#asm
   //configure port b, c as output
   MOVLW 0x00
   TRIS PORTB
   TRIS PORTC
#endasm

   write(PORTB, dat[1]);
   write(PORTC, dat[0]);
   write(PORTA, SIGNAL_READY);

   return 0;
}

