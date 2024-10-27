#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
	

void draw_line(int x0, int y0, int x1, int y1, int colour);
void plot_pixel(int x, int y, short int line_color);
void swap(int *a, int *b);
void clear_screen();
void wait_for_sync();

volatile int pixel_buffer_start; // global variable


int main(void)
{
    volatile int * pixel_ctrl_ptr = (int *)0xFF203020;
    /* Read location of the pixel buffer from the pixel buffer controller */
    pixel_buffer_start = *pixel_ctrl_ptr;
	
	clear_screen();
	
	while(1){
		
		for(int y = 0; y < 239; y++){
			draw_line(0, y, 319, y, 0xF81F);
			wait_for_sync();
			draw_line(0, y, 319, y, 0x000);
		}
		for(int y = 239; y > 0; y--){
			draw_line(0, y, 319, y, 0xF81F);
			wait_for_sync();
			draw_line(0, y, 319, y, 0x000);
		}
	}
}

void wait_for_sync(){
	volatile int *pixel_ctrl_ptr = 0xFF203020; //pixel controller
	register int status;
	
	*pixel_ctrl_ptr = 1; //starts the synchronization process 
	
	status = *(pixel_ctrl_ptr + 3); //reads the status register
	while ((status & 0x01) != 0){
		status = *(pixel_ctrl_ptr + 3); //checks s bit
	}
}

void plot_pixel(int x, int y, short int line_color)
{
    *(short int *)(pixel_buffer_start + (y << 10) + (x << 1)) = line_color;
}

void clear_screen(){
	for (int x = 0; x < 320; x++){
		for (int y = 0; y < 240; y++){
			plot_pixel(x, y, 0x0000);
		}
	}
}

void swap(int *a, int *b){
    int temp = *a;
    *a = *b;
    *b = temp;
}

void draw_line(int x0, int y0, int x1, int y1, int colour){
	bool is_steep = abs(y1 - y0) > abs(x1 - x0);
	if (is_steep){
		swap(&x0, &y0);
		swap(&x1, &y1);
	}
	if (x0 > x1){
		swap(&x0, &x1);
		swap(&y0, &y1);
	}
	
	int deltax = x1 - x0;
	int deltay = abs(y1 - y0);
	int error = -(deltax / 2);
	int y = y0;
	
	int y_step = 0;
	
	if (y0 < y1){
		y_step = 1;
	}
	else{
		y_step = -1;
	}
	
	for (int x = x0; x < x1; x++){
		if (is_steep){
			plot_pixel(y, x, colour);
		}
		else{
			plot_pixel(x, y, colour);
		}
		error = error + deltay;
		
		if (error > 0){
			y = y + y_step;
			error = error - deltax;
		}
	}
}
