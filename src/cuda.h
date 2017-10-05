/*
 * CPU.h
 *
 *  Created on: 24-09-2017
 *      Author: vichoko
 */


/** cpp interface **/
int* init_game_data();

int* kernel_wrapper(); // call every frame

void free_resources();
void free_cuda_resources();


