#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>

void wait_for_sync();
void clear_screen();
void plot_pixel(int x, int y, short int line_color);
void draw(int x_box[], int y_box[], int dx_box[], int dy_box[], int box_colour);
void draw_box(int boxNum, int x_box[], int y_box[], int box_colour);
void draw_line(int x0[], int y0[], int x1[], int y1[], int colour);
void swap(int *a, int *b);

volatile int pixel_buffer_start; // global variable
int x_box_old[8];
int y_box_old[8];

int x_box_older[8];
int y_box_older[8];


int main(void)
{
    volatile int * pixel_ctrl_ptr = (int *)0xFF203020;
    // declare other variables(not shown)
	
	srand(time(0));
	
	int x_box[8];
	int y_box[8];
	
	int dx_box[8];
	int dy_box[8];
	
	
	 // initialize location and direction of rectangles(not shown)
	
	for(int i = 0; i < 8; i++){
		x_box[i] = (rand() % (319 - 0 + 1)) + 0;
		y_box[i] = (rand() % (239 - 0 + 1)) + 0;
		
		dx_box[i] = ((rand() % 2) * 2) - 1; //makes it either -1 or 1
		dy_box[i] = ((rand() % 2) * 2) - 1; //makes it either -1 or 1
	}
	
	
	// random colour for the box
	
	int colour[5] = {0xFFE0, 0x07FF, 0xF81F, 0xFC18, 0xFC00};
	
	int ranIndex = rand() % 5;
	
	int box_colour = colour[ranIndex];

    /* set front pixel buffer to start of FPGA On-chip memory */
    *(pixel_ctrl_ptr + 1) = 0xC8000000; // first store the address in the 
                                        // back buffer
    /* now, swap the front/back buffers, to set the front buffer location */
    wait_for_sync();
    /* initialize a pointer to the pixel buffer, used by drawing functions */
    pixel_buffer_start = *pixel_ctrl_ptr;
    clear_screen(); // pixel_buffer_start points to the pixel buffer
    /* set back pixel buffer to start of SDRAM memory */
    *(pixel_ctrl_ptr + 1) = 0xC0000000;
    pixel_buffer_start = *(pixel_ctrl_ptr + 1); // we draw on the back buffer
    clear_screen(); // pixel_buffer_start points to the pixel buffer
	
    //wait_for_sync();
   
	while (1)
    {
		
        /* Erase any boxes and lines that were drawn in the last iteration */
		
		
		//draw(x_box_older, y_box_older, dx_box, dy_box, 0x0000);

		clear_screen();

        // code for drawing the boxes and lines (not shown)
		
		draw(x_box, y_box, dx_box, dy_box, box_colour);
		
        // code for updating the locations of boxes (not shown)
		
		
		wait_for_sync(); // swap front and back buffers on VGA vertical sync
		
        pixel_buffer_start = *(pixel_ctrl_ptr + 1); // new back buffer
		
		//draw(x_box_old, y_box_old, dx_box, dy_box, 0x0000);
    }
}

void draw(int x_box[], int y_box[], int dx_box[], int dy_box[], int box_colour){
	
	for(int i = 0; i < 8; i++){
		draw_box(i, x_box, y_box, box_colour);
		
		int nextBox = i+1;
		
		if(nextBox < 8){
			draw_line(x_box[i], y_box[i], x_box[nextBox], y_box[nextBox], box_colour);
		}
		else{
			draw_line(x_box[0], y_box[0], x_box[i], y_box[i], box_colour);

		}
	}
	
	for(int i = 0; i < 8; i++){

		x_box_older[i] = x_box_old[i];
		y_box_older[i] = y_box_old[i];

		x_box_old[i] = x_box[i];
		y_box_old[i] = y_box[i];
		
		//This is supposed to make the boxes change directions after hitting a boundary
		//but it doesnt work :(
		/*
		if(x_box[i] <= 0 || x_box >= 319){
			dx_box[i] = -1 * dx_box[i];
		}

		if(y_box[i] <= 0 || y_box >= 239){
			dy_box[i] = -1 * dy_box[i];
		}*/

		x_box[i] += dx_box[i];
		y_box[i] += dy_box[i];
			
	}
	
}

void draw_box(int boxNum, int x_box[], int y_box[], int box_colour){	
	for(int r = 0; r < 4; r++){
		for(int c = 0; c < 4; c++){
			plot_pixel(x_box[boxNum] + r, y_box[boxNum] + c, box_colour);
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

void clear_screen(){
	for (int x = 0; x < 320; x++){
		for (int y = 0; y < 240; y++){
			plot_pixel(x, y, 0x0000);
		}
	}
}

void plot_pixel(int x, int y, short int line_color)
{
    *(short int *)(pixel_buffer_start + (y << 10) + (x << 1)) = line_color;
}

void swap(int *a, int *b){
    int temp = *a;
    *a = *b;
    *b = temp;
}

void draw_line(int x0[], int y0[], int x1[], int y1[], int colour){
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

	