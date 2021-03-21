/*

Nyan Cat for the NES
Oscar C-R/TôBach - 2021
Started:	8:45PM 	19/03/21
Finished: 	4:20AM 	21/03/21

I am bad at C programming, 
do not code like this :^)

*/

#include "neslib.h"
#include "LIB/nesdoug.h"
#include "Sprites.h"
#include "bg.h"
#include "bg2.h"
#include "bg3.h"
#include "tail.h"
#include "feet.h"
#include "stars.h"
#pragma bss-name(push, "ZEROPAGE")

//normal include stuff

unsigned char y_position=0x70;
unsigned char x_position=0x98;
//unsigned char x_position3=0xc0;
unsigned char i, j, scroll_x_new, scroll_x_new2, star_x;
unsigned char tail_x = 0x60;
unsigned char tail_y = 0x70;

//variables

const unsigned char palette_sp[]={
0x11, 0x25, 0x2D, 0x0F,
0x25, 0x25, 0x0F, 0x0F,
0x11, 0x25, 0x2D, 0x0F,
0x11, 0x25, 0x2D, 0x30,
};

//sprite palettes

const unsigned char palette_bg[]={
0x02, 0x25, 0x37, 0x0f,
0x14, 0x25, 0x37, 0x0f,
0x02, 0x15, 0x27, 0x19,
0x02, 0x19, 0x0c, 0x13,
}; 

//background palettes

const unsigned char head_x[]={
0x92, 0x92, 0x92, 0x92, 0x94, 0x94, 0x94, 0x94, 0x94, 0x94, 0x94, 0x94, 0x92, 0x92, 0x92, 0x92
};

//cat head position x

const unsigned char head_y[]={
0x70, 0x70, 0x6e, 0x6e, 0x6e, 0x6e, 0x6e, 0x6e, 0x6e, 0x6e, 0x70, 0x70, 0x70, 0x70, 0x70, 0x70
};

//cat head position y

const unsigned char feet_y[]={
0x7B, 0x7D, 0x7D, 0x7D, 0x7D, 0x7D, 0x7D, 0x7D, 0x7D, 0x7B, 0x7B, 0x7B, 0x7B, 0x7B, 0x7B, 0x7B
};

/*
const unsigned char scroll_screen_x[]={
0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF
};
*/

//background nametable scroll x

const unsigned char scroll_screen_y[]={
0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0
};

/*background nametable scroll y

the idea here was to have each 4 background frames
stored in each nametable and then cycle between them,
but that's not how it works, i found out the hard way!
only the two nametables on the left are different and the other two on the right
are mirrors of the first two!

an hour and a half i will never get back :^(

a way of doing it would be to cycle through them and then write them in the background
and then switch from the two different nametables, but my brain is too small to figure
that out

all these arrays have 4 of each position in each,
this is because i'm too scared to just use one and
then just cycle it slower with a different index
since i'm still quite dodgy with nes stuff,
i'll learn it eventually, but for now
this method works so ¯\_(ツ)_/¯

*/

const unsigned char* const stars[]={

stars_0_data,
stars_0_data,
stars_0_data,
stars_0_data,

stars_1_data,
stars_1_data,
stars_1_data,
stars_1_data,

stars_2_data,
stars_2_data,
stars_2_data,
stars_2_data,

stars_3_data,
stars_3_data,
stars_3_data,
stars_3_data,

stars_4_data,
stars_4_data,
stars_4_data,
stars_4_data,

stars_5_data,
stars_5_data,
stars_5_data,
stars_5_data

};

const unsigned char* const nyan_feet[]={

feet_3_data,
feet_3_data,

feet_4_data,
feet_4_data,
feet_4_data,
feet_4_data,

feet_5_data,
feet_5_data,
feet_5_data,
feet_5_data,

feet_0_data,
feet_0_data,
feet_0_data,
feet_0_data,

feet_1_data,
feet_1_data,
feet_1_data,
feet_1_data,

feet_2_data,
feet_2_data,
feet_2_data,
feet_2_data,

feet_3_data,
feet_3_data

};

const unsigned char* const nyan_tail[]={

tail_3_data,
tail_3_data,
tail_3_data,
tail_3_data,

tail_4_data,
tail_4_data,
tail_4_data,
tail_4_data,

tail_0_data,
tail_0_data,
tail_0_data,
tail_0_data,

tail_1_data,
tail_1_data,
tail_1_data,
tail_1_data,

tail_2_data,
tail_2_data,
tail_2_data,
tail_2_data
};

//Also yes i just copy and paste it 4 times to make it slower, still scared to mess
//with timings on the NES, i promise I will learn one day !!

void main(void)
{
	static unsigned char sprid;
	
	ppu_off();

	bank_spr(0);

	pal_spr(palette_sp);
	pal_bg(palette_bg);
	
	vram_adr(NAMETABLE_A);
	vram_unrle(bg2);
	
	vram_adr(NAMETABLE_B);
	vram_unrle(bg3);

	vram_adr(NAMETABLE_C);
	vram_unrle(bg);
	
	vram_adr(NAMETABLE_D);
	vram_unrle(bg2);
	
	//Writes the RLE tilemaps to their respected nametables
	//the "vram_adr(NAMETABLE_A);" parts i still left in underneath, even though
	//there is something wrong with them, they seem to work with mirroring still

	music_play(0);

	//music maestro!

	delay(165);
	ppu_on_all();

	//initial delay before the demo starts, just like the original video

	sprid = rand8();

	while(1)
	{
		ppu_wait_nmi();
		oam_clear();
		sprid = rand8()*4;
		i++;
		j++;

		if (i>15){
		i=0;
		}

		if (j>19){
		j=0;
		}

		sprid = oam_meta_spr(head_x[i], head_y[i]+3, sprid, metasprite_0_data);
		sprid = oam_meta_spr(tail_x, tail_y, sprid, nyan_tail[j]);
		sprid = oam_meta_spr(0x75, feet_y[i], sprid, nyan_feet[i]);
		
		// all the objects for the cat

		sprid = oam_meta_spr(star_x, 0x00, sprid, stars[j]);
		sprid = oam_meta_spr(star_x+0x20, 0x20, sprid, stars[j+1]);
		sprid = oam_meta_spr(star_x+0xA0, 0x48, sprid, stars[j+3]);
		
		sprid = oam_meta_spr(star_x+0x40, 0x90, sprid, stars[j+4]);
		sprid = oam_meta_spr(star_x+0xC0, 0xA0, sprid, stars[j+2]);
		sprid = oam_meta_spr(star_x+0x70, 0xE8, sprid, stars[j+1]);

		//all the stars

		star_x=star_x-8;

		//move the stars

		/*
		scroll_x_new = scroll_screen_x[i];
		if (scroll_x_new=0xFF){
			scroll_x_new2 = scroll_x_new + 1;
		}
		*/
		scroll(0x00,scroll_screen_y[i]);
		//scroll the screen through the nametables
	}

}