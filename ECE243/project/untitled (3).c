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
void drawGameBoard();
void highlightNextMove(Box b);
void placeNextMove(Box B);
bool gameEnd();
	
int main(void)
{
	
}

void initializeGameBoard(){
	for(int r = 0; r<ROW; r++){
		for(int c = 0; c<COL; c++){
			if((r%2!=0)&&(c%2!=0)){
				
			}
			else{
				Box b;
				b.state = "empty";
				b.type = "blankBox";
			}
}

//for testing
void drawGameBoard(){
	for(int r = 0; r<ROW; r++){
		for(int c = 0; c<COL; c++){
			if(GameBoard[r][c].type == "blankBox"){
				cout << "   ";
			}
			else if(GameBoard[r][c].type == "redBox"){
				cout << "R";
			}
			else if(GameBoard[r][c].type == "greenBox"){
				cout << "G";
			}
			else{
				cout << "X";
			}
			
			if(GameBoard[r][c].type == "empty"){
				cout << "  ";
			}
			else if(GameBoard[r][c].type == "red"){
				cout << "R ";
			}
			else if(GameBoard[r][c].type == "green"){
				cout << "G ";
			}
			
			cout << endl << endl;
}
