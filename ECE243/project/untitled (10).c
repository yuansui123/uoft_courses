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
	int state; //state can be either empty, red or green 
	int type; //type can be either blankBox, redBox, greenBox or gameBox
	bool highlighted; //true if the box is highlighted, false otherwise
};

struct Box initBox(int r, int c, int s, int t) {
	struct Box b;
	b.row = r;
	b.col = c;
	b.state = s;
	b.type = t;
	b.highlighted = false;
	return b;
}

// Global Variables
// Game Board that will hold all the Box values
struct Box GameBoard[ROW][COL]; //(0,0) at the down left corner
						//(34,18) at the top right corner
int NextRowMoves[8]; //max number of possible next moves is 8
int NextColMoves[8]; //-1 means the position is empty 

void initializeGameBoard();
void drawGameBoard();
void changeGameBoard(int row, int col, int player);
bool highlightNextMove(struct Box b, int player);
void placeNextMove(struct Box B);
bool gameEnd();

//helper functions
bool selectedBoxIsValid(struct Box b, int player);
bool nextBoxIsValid(struct Box b, int player);
bool rowAndColIsValid(int row, int col);

int main(void)
{
	initializeGameBoard();
	drawGameBoard();
	
	changeGameBoard(0, 8, RED);
	highlightNextMove(GameBoard[0][8], RED);
	drawGameBoard();
}
		
void changeGameBoard(int row, int col, int player){
		if(rowAndColIsValid(row, col)){
			GameBoard[row][col].state = player;
		}
}
//check if the selected box is valid
//false if row and col out of range
//false if the box type is blank box
//false if the box state is empty 
//flase if the box state is not the player color
bool selectedBoxIsValid(struct Box b, int player){
	if(b.row <0 || b.row >= ROW){
		return false;
	}
	if(b.col <0 || b.col >= COL){
		return false;
	}
	if(b.type == BLANKBOX){
		return false;
	}
	if(b.state == EMPTY){
		return false;
	}
	if(b.state!=player){
		return false;
	}
	
	return true;
}

//check if the next box is valid
//false if row and col out of range
//false if box type is blank box
//false if box type is not empty
bool nextBoxIsValid(struct Box b, int player){
	if(b.row <0 || b.row >= ROW){
		return false;
	}
	if(b.col <0 || b.col >= COL){
		return false;
	}
	if(b.type == BLANKBOX){
		return false;
	}
	if(b.state != EMPTY){
		return false;
	}
	
	return true;
}

//check if row and col is within bound
bool rowAndColIsValid(int row, int col){
	if(row <0 || row >= ROW){
		return false;
	}
	if(col <0 || col >= COL){
		return false;
	}
    return true;
}

//highlight next move on the gameboard
//return false if the selected Box b is illegal
//return true after highlighting the next moves 
bool highlightNextMove(struct Box b, int player){
	
	if(!selectedBoxIsValid(b, player)){
		return false;
	}
	
	int playerRow = b.row;
	int playerCol = b.col;
	
	if(!rowAndColIsValid(playerRow, playerCol)){
		return false;
	}
	
	//eight possible moves
	int nextRowIncre[] = {1, 1,-1,-1, 2, 2,-2,-2};
	int nextColIncre[] = {1,-1, 1,-1, 2,-2, 2,-2};
	//immediate four moves
	for(int i = 0; i<4; i++){
		
		int nextRow = playerRow + nextRowIncre[i];
		int nextCol = playerCol + nextColIncre[i];
		
		if(rowAndColIsValid(nextRow, nextCol)){
			if(nextBoxIsValid(GameBoard[nextRow][nextCol], player)){
				GameBoard[nextRow][nextCol].highlighted = true;
				NextRowMoves[i] = nextRow;
				NextColMoves[i] = nextCol;
		}
    }
	//jumping four moves	   
    for(int i = 4; i<8; i++){
		
		int nextRow = playerRow + nextRowIncre[i-4];
		int nextCol = playerCol + nextColIncre[i-4];
		int nextnextRow = playerRow + nextRowIncre[i];
	    int nextnextCol = playerCol + nextColIncre[i];
		
		if(rowAndColIsValid(nextnextRow, nextnextCol)){
			if(nextBoxIsValid(GameBoard[nextnextRow][nextnextCol], player)){
				if(selectedBoxIsValid(GameBoard[nextRow][nextCol], player)){
					GameBoard[nextnextRow][nextnextCol].highlighted = true;
					NextRowMoves[i] = nextnextRow;
					NextColMoves[i] = nextnextCol;
				}
			}
		}
    }
}


void initializeGameBoard() {
	//initialize next moves 
	for(int i = 0; i<8; i++){
		NextRowMoves[i] = -1;
		NextRowMoves[i] = -1;
	}
	
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
							GameBoard[r][c] = initBox(r, c, RED, REDBOX);
							isBlankBox = false;
						}
						else if (c >= 13) {
							GameBoard[r][c] = initBox(r, c, GREEN, GREENBOX);
							isBlankBox = false;
						}
						else {
							GameBoard[r][c] = initBox(r, c, EMPTY, GAMEBOX);
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
							GameBoard[r][c] = initBox(r, c, RED, REDBOX);
							isBlankBox = false;
						}
						else if (c >= 13) {
							GameBoard[r][c] = initBox(r, c, GREEN, GREENBOX);
							isBlankBox = false;
						}
						else {
							GameBoard[r][c] = initBox(r, c, EMPTY, GAMEBOX);
							isBlankBox = false;
						}
					}
				}
			}

			if (isBlankBox) {
				//will only reach here if the box is empty blank box
				GameBoard[r][c] = initBox(r, c, EMPTY, BLANKBOX);
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
				printf("_");
			}
			else if (GameBoard[r][c].state == RED) {
				printf("R");
			}
			else if (GameBoard[r][c].state == GREEN) {
				printf("G");
			}
			
			if (GameBoard[r][c].highlighted == true){
				printf("O");
			}else{
				printf("_");
			}

		}
		printf("\n\n");
	}
	
	for(int i = 0; i<8; i++){
			printf("%d,%d  ", NextRowMoves[i], NextColMoves[i]);
	}
}

	
	