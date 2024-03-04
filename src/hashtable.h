/**
 * @author Korbin Shelley
 * @date: March 03, 2024
 * @file: hashtable.h
 * @brief: Declarations for the hash table data structure
 * 
 * @version: 0.4.6
*/

#ifndef HASHTABLE_H
#define HASHTABLE_H

#define HASH_SIZE 33
// https://datastructures.maximal.io/hash-tables/

typedef struct ht_item *HashItem;
typedef struct hash_table *HashTable;

struct ht_item {
    char *key;
    void *value;
    HashItem next; // Pointer to the next item in the linked list
};

struct hash_table {
    int count;
    // ht_item *items[SIZE];
    HashItem items[HASH_SIZE];
};

HashTable ht_create();
void ht_delete(HashTable ht);
void ht_insert(HashTable ht, char *key, void *value);
void *ht_search(HashTable ht, char *key);
void ht_delete_item(HashTable ht, char *key);
void ht_print(HashTable ht);

#endif