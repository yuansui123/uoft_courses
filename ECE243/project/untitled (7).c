#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <string.h>

#define ROW 17
#define COL 17

#define EMPTY 0
#define RED 1
#define GREEN 2

#define BLANKBOX 3
#define REDBOX 4
#define GREENBOX 5
#define GAMEBOX 6

// This struct define each box on the game board
struct Box {
	int row; //position of the box on the game board
	int col; 
	int state; //state can be either 0 = empty, 1 = red or 2 = green 
	int type; //type can be either 0 = blankBox, 1 = redBox, 2 = greenBox or 3 = gameBox
};

// Global Variables
// Game Board that will hold all the Box values
struct Box GameBoard[ROW][COL]; //(0,0) at the down left corner
						//(34,18) at the top right corner
struct Box NextMoves[12]; //max number of possible next moves is 6

void initializeGameBoard();
void drawGameBoard();
void highlightNextMove(struct Box b);
void placeNextMove(struct Box B);
bool gameEnd();

struct Box initBox(int s, int t) {
	struct Box b;
	b.state = s;
	b.type = t;
	return b;
}

int main(void)
{
	initializeGameBoard();
	drawGameBoard();
}

void initializeGameBoard() {
	//iterate through every box on the gameboard
	for (int r = 0; r < ROW; r++) {
		for (int c = 0; c < COL; c++) {

			bool isBlankBox = true;

			//if row is even number
			if (r % 2 == 0) {
				//compute range of col covered in this row
				int halfLength = 0;
				if (r > ((ROW - 1) / 2)) {
					halfLength = ((ROW - 1) - r) / 2;
				}
				else {
					halfLength = (r) / 2;
				}

				if ((c >= ((ROW - 1) / 2) - halfLength * 2)
					&& (c <= ((ROW - 1) / 2) + halfLength * 2)) {
					if (((ROW - 1) / 2 - c) % 2 == 0) {
						if (c <= 3) {
							GameBoard[r][c] = initBox(RED, REDBOX);
							isBlankBox = false;
						}
						else if (c >= 13) {
							GameBoard[r][c] = initBox(GREEN, GREENBOX);
							isBlankBox = false;
						}
						else {
							GameBoard[r][c] = initBox(EMPTY, GAMEBOX);
							isBlankBox = false;
						}
					}
				}
			}
			//if row is odd number
			else {
				//compute range of col covered in this row
				int halfLength = 0;
				if (r > ((ROW - 1) / 2)) {
					halfLength = ((ROW - 1) - r + 1) / 2;
				}
				else {
					halfLength = (r + 1) / 2;
				}

				if ((c >= ((ROW - 1) / 2) - 1 - (halfLength - 1) * 2)
					&& (c <= ((ROW - 1) / 2) + 1 + (halfLength - 1) * 2)) {
					if (((ROW - 1) / 2 - 1 - c) % 2 == 0) {
						if (c <= 3) {
							GameBoard[r][c] = initBox(RED, REDBOX);
							isBlankBox = false;
						}
						else if (c >= 13) {
							GameBoard[r][c] = initBox(GREEN, GREENBOX);
							isBlankBox = false;
						}
						else {
							GameBoard[r][c] = initBox(EMPTY, GAMEBOX);
							isBlankBox = false;
						}
					}
				}
			}

			if (isBlankBox) {
				//will only reach here if the box is empty blank box
				GameBoard[r][c] = initBox(EMPTY, BLANKBOX);
			}
		}
	}
}

//for testing
void drawGameBoard() {
	for (int r = 0; r < ROW; r++) {
		for (int c = 0; c < COL; c++) {
			if (GameBoard[r][c].type == BLANKBOX) {
				printf("___");
				continue;
			}
			else if (GameBoard[r][c].type == REDBOX) {
				printf("R");
			}
			else if (GameBoard[r][c].type == GREENBOX) {
				printf("G");
			}
			else if (GameBoard[r][c].type == GAMEBOX) {
				printf("X");
			}

			if (GameBoard[r][c].state == EMPTY) {
				printf("__");
			}
			else if (GameBoard[r][c].state == RED) {
				printf("R_");
			}
			else if (GameBoard[r][c].state == GREEN) {
				printf("G_");
			}

		}
		printf("\n\n");
	}
}

	
	