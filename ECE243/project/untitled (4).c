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

Box initBox(string s, string t){
	Box b;
	b.state = s;
	b.type = t;
	return b;
}

void initializeGameBoard(){
	//iterate through every box on the gameboard
	for(int r = 0; r<ROW; r++){
		for(int c = 0; c<COL; c++){
			
			bool isBlankBox = true;
			
			if((c%2!=0)&&(c!=0)&&(c!=COL)&&(r!=0)&&(r!=ROW)){
				//if row is odd number
				if(r%2!=0){ 
					//compute range of col covered in this row
					int halfLength = 0;
					if(r>9){
						halfLength = ((18-r)-1)/2;
					}else{
						halfLength = (r-1)/2;
					}
					
					if((c>=(17-halfLength*4)
					   &&(c<=(17+halfLength*4)){
					   if((17-c)%4 == 0){
						   if(c <= 7){
							   GameBoard[r][c] = initBox("red", "redBox");
							   isBlankBox == false;
						   }
						   else if(c >= 27){
							   GameBoard[r][c] = initBox("green", "greenBox");
							   isBlankBox == false;
						   else{
							   GameBoard[r][c] = initBox("empty", "gameBox");
							   isBlankBox == false;
						   }
					}
						   
				}
				//if row is even number
				else{ 
					//compute range of col covered in this row
					int halfLength = 0;
					if(r>9){
						halfLength = ((18-r)/2);
					}else{
						halfLength = r/2;
					}
					
					if((c>=(17-(2+(halfLength-1)*4))
					   &&(c<=(17+(2+(halfLength-1)*4))){
					   if((17-2-c)%4 == 0){
						   if(c <= 7){
							   GameBoard[r][c] = initBox("red", "redBox");
							   isBlankBox == false;
						   }
						   else if(c >= 27){
							   GameBoard[r][c] = initBox("green", "greenBox");
							   isBlankBox == false;
						   else{
							   GameBoard[r][c] = initBox("empty", "gameBox");
							   isBlankBox == false;
						   }
					}
				}
			}
			if(isBlankBox){
				//will only reach here if the box is empty blank box
		    	GameBoard[r][c] = initBox("empty", "blankBox");
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
