#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
	
#define ROW 18;
#define COL 34;
	
// This struct define each box on the game board
Struct Box{
	string state; //state can be either "empty", "red" or "green" 
	string type: //type can be either "blankBox", "redBox", "greenBox" or "gameBox"
}

// Global Variables
// Game Board that will hold all the Box values
Box GameBoard [ROW][COL]; //(0,0) at the down left corner
						//(34,18) at the top right corner
Box NextMoves [12]; //max number of possible next moves is 6

void initializeGameGoard();
void highlightNextMove(Box b);
void placeNextMove(Box B);
bool gameEnd();
	
//for testing
void drawGameBoard(){
	for(int i = 0; i<ROW; i++){
		for(int j = 0; i<COL; j++){
			if(GameBoard[i][j].type == "blankBox"){
				cout << "   ";
			}
			else if(GameBoard[i][j].type == "redBox"){
				cout << "R";
			}
			else if(GameBoard[i][j].type == "greenBox"){
				cout << "G";
			}
			else{
				cout << "X";
			}
			
			if(GameBoard[i][j].type == "empty"){
				cout << "  ";
			}
			else if(GameBoard[i][j].type == "red"){
				cout << "R ";
			}
			else if(GameBoard[i][j].type == "green"){
				cout << "G ";
			}
			
			cout << endl << endl;
}

int main(void)
{
	
}