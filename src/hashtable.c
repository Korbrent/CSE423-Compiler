/**
 * @author Korbin Shelley
 * @date: March 03, 2024
 * @file: hashtable.c
 * @brief: Function implementations for manipulating a hash table
 * 
 * @version: 0.4.6
*/

/**
 * Cool beans, writing a hashtable was kinda fun.
 * Now that I made it generic, I will never have to do it again.
 * The beauty of programming. Write once, use forever! <3
 * 
 * I doubt you read my comments... 
 * Hi Dr. J :)
*/

#include "hashtable.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Create a new hash table
HashTable ht_create() {
    HashTable table = malloc(sizeof(struct hash_table));
    for (int i = 0; i < HASH_SIZE; i++) {
        table->items[i] = NULL;
    }
    return table;
}

// Delete a hash table
void ht_delete(HashTable ht) {
    // TODO: Implement this
    for (int i = 0; i < HASH_SIZE; i++) {
        HashItem item = ht->items[i];
        while (item != NULL) {
            HashItem temp = item;
            item = item->next;
            temp->next = NULL;
            // TODO: THIS IS HARD
            free(temp);
        }
    }
}

// Hash a string to an index
// http://www.cse.yorku.ca/~oz/hash.html
unsigned int hash(char *key) {
    unsigned int hash = 0;
    for (int i = 0; key[i] != '\0'; i++) {
        hash = (hash << 5) + key[i];
    }
    return hash % HASH_SIZE;
}

// Insert a key-value pair into the hash table
void ht_insert(HashTable ht, char *key, void *value) {
    fprintf(stderr, "in ht_insert\n");
    if(ht_search(ht, key) != NULL){
        printf("Key already exists in the hash table\n");
        return;
    }
    int index = hash(key);
    fprintf(stderr,"key %s hash %d\n",key,index);

    HashItem new_item = malloc(sizeof(struct ht_item));
    new_item->key = key;
    new_item->value = value;
    new_item->next = ht->items[index];
    ht->items[index] = new_item;

    for(int i=0; i<HASH_SIZE; i++)
    {
        if(ht->items[i] != NULL)
            fprintf(stderr,"index %d has %s\n",i,ht->items[i]->key);
    }
}

// Search for a key in the hash table
void *ht_search(HashTable ht, char *key) {
    fprintf(stderr, "in ht_search\n");
    int index = hash(key);
    fprintf(stderr,"key %s hash %d\n",key,index);

    for(int i=0; i<HASH_SIZE; i++)
    {
        if(ht->items[i] != NULL)
            fprintf(stderr,"index %d has %s\n",i,ht->items[i]->key);
    }

    HashItem item = ht->items[index];
    while (item != NULL) {
        fprintf(stderr,"found %s\n",item->key);
        if (strcmp(item->key, key) == 0) {
            return item->value;
        }
        item = item->next;
    }
    return NULL;
}

// Delete an item from the hash table
void ht_delete_item(HashTable ht, char *key) {
    int index = hash(key);
    HashItem item = ht->items[index];
    HashItem prev = NULL;
    while (item != NULL) {
        if (strcmp(item->key, key) == 0) {
            if (prev == NULL) {
                ht->items[index] = item->next;
            } else {
                prev->next = item->next;
            }
            free(item);
            return;
        }
        prev = item;
        item = item->next;
    }
}

// Print the hash table
void ht_print(HashTable ht) {
    for (int i = 0; i < HASH_SIZE; i++) {
        HashItem item = ht->items[i];
        printf("Bucket %d: ", i);
        while (item != NULL) {
            // Print the address of the value to make it easier to debug
            printf("(%s, %p) ", item->key, item->value);
            item = item->next;
        }
        printf("\n");
    }
}