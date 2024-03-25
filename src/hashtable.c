/**
 * @author Korbin Shelley
 * @date: March 03, 2024
 * @file: hashtable.c
 * @brief: Function implementations for manipulating a hash table
 * 
 * @version: 0.4.6
*/

#include "hashtable.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/**
 * Create a new HashTable
 * @return HashTable type, must be deleted with ht_delete().
 */
HashTable ht_create() {
    HashTable table = malloc(sizeof(struct hash_table));
    for (int i = 0; i < HASH_SIZE; i++) {
        table->items[i] = NULL;
    }
    return table;
}

/**
 * Delete a HashTable
 * @param ht HashTable to be deleted
 * @note The elements within the hashtable should be freed elsewhere.
 */
void ht_delete(HashTable ht) {
    for (int i = 0; i < HASH_SIZE; i++) {
        HashItem item = ht->items[i];
        while (item != NULL) {
            HashItem temp = item;
            item = item->next;
            temp->next = NULL;
            temp->key = NULL;
            temp->value = NULL;
            free(temp);
        }
        ht->items[i] = NULL;
    }
    free(ht);

}

// Hash a string to an index
// http://www.cse.yorku.ca/~oz/hash.html
/**
 * Hashes a string to an index for the hash-table.
 * @return index in table
*/
int hash(char *key) {
    unsigned int hash = 0;
    for (int i = 0; key[i] != '\0'; i++) {
        hash = (hash << 5) + key[i];
    }
    return hash % HASH_SIZE;
}

/**
 * Inserts a key-value pair into a HashTable
 * @param ht HashTable to be added to
 * @param key the key to be indexed by
 * @param value a pointer datatype
 * @note key and value must be freed outside of the hashtable. 
*/
void ht_insert(HashTable ht, char *key, void *value) {
    if(ht_search(ht, key) != NULL){
        fprintf(stderr, "Key already exists in the hash table. Should be checked before inserting.\nIgnoring for now.\n");
        return;
    }
    int index = hash(key);

    HashItem new_item = malloc(sizeof(struct ht_item));
    new_item->key = key;
    new_item->value = value;
    new_item->next = ht->items[index];
    ht->items[index] = new_item;
}

/**
 * Search for a key in the hash table
 * @param ht HashTable to be searched
 * @param key Key to be used during search
 * @return pointer to value 
 * @note must be casted to expected type
 */
void *ht_search(HashTable ht, char *key) {
    int index = hash(key);

    HashItem item = ht->items[index];
    while (item != NULL) {
        if (strcmp(item->key, key) == 0) {
            return item->value;
        }
        item = item->next;
    }
    return NULL;
}

/**
 * Delete an item from the HashTable
 * @param ht HashTable to delete from
 * @param key key to be deleted
 * @note Does not free the key nor value. Only the entry in the HT
 */
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