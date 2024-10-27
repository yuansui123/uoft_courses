#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
	
// this struct define each box on the game board
Struct Box{
	string state; //state can be either "empty", "red" or "green" 
	string type: //type can be either "blankBox", "redBox", "greenBox" or "
}

//Game Board that will hold all the Box values
Box gameBoard [34][18];

void initializeGameGoard();
void highlightNextMove(Box b);


int main(void)
{
	
}