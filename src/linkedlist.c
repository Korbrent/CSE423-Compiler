#include "linkedlist.h"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>

/**
 * Create a new List
 * @return List type
 */
List ll_create() {
    List list = (List)malloc(sizeof(struct list_t));
    list->head = NULL;
    list->tail = NULL;
    list->size = 0;
    return list;
}

/**
 * Delete a List
 * @param list List to be deleted
 * @note the elements within the list should be freed elsewhere
 */
void ll_delete(List list) {
    Node current = list->head;
    while (current != NULL) {
        Node next = current->next;
        if(current->data != NULL)
            fprintf(stderr, "Data within linked list should be freed before destroying the list!\n");
        free(current);
        current = next;
    }
    free(list);
}

/**
 * Add an element to the List
 * @param list List to be added to
 * @param data pointer to the data type to be inserted
 */
void ll_add(List list, void *data) {
    assert(list != NULL);
    Node node = (Node)malloc(sizeof(struct node_t));
    node->data = data;
    node->next = NULL;
    node->prev = list->tail;
    if (list->tail != NULL) {
        list->tail->next = node;
    }
    if (list->head == NULL) {
        list->head = node;
    }
    list->tail = node;
    list->size++;
}

/**
 * Insert element into the List
 * @param list List to be added to
 * @param data pointer to data to be inserted
 * @param index index to insert in 
*/
void ll_insert(List list, void *data, int index) {
    if (index < 0 || index >= list->size) {
        fprintf(stderr, "Index out of bounds\n");
        return;
    }
    Node node = (Node)malloc(sizeof(struct node_t));
    node->data = data;
    if (index == 0) {
        node->next = list->head;
        node->prev = NULL;
        if (list->head != NULL) {
            list->head->prev = node;
        }
        list->head = node;
    } else {
        if (list->size - index < index) {
            // Faster to start from the tail
            Node current = list->tail;
            for (int i = list->size - 1; i > index; i--) {
                current = current->prev;
            }
            node->next = current;
            node->prev = current->prev;
            current->prev->next = node;
            current->prev = node;
        } else {
            // Faster to start from the head
            Node current = list->head;
            for (int i = 0; i < index - 1; i++) {
                current = current->next;
            }
            node->next = current->next;
            node->prev = current;
            current->next->prev = node;
            current->next = node;
        }
    }
    list->size++;
}

/**
 * Gets data from the List
 * @param list List to get data from
 * @param index index of data to get
 * @return pointer to data at index
 * @note must be cast to expected return type
*/
Data ll_get(List list, int index) {
    if (index < 0 || index >= list->size) {
        fprintf(stderr, "Index out of bounds\n");
        return NULL;
    }
    Node current;
    if (index < list->size / 2) {
        current = list->head;
        for (int i = 0; i < index; i++) {
            current = current->next;
        }
    } else {
        current = list->tail;
        for (int i = list->size - 1; i > index; i--) {
            current = current->prev;
        }
    }
    return current->data;
}

/**
 * Remove an element from the List
 * @param list List to be removed from
 * @param index index to remove
 * @return pointer to data that was removed
*/
Data ll_remove(List list, int index) {
    if (index >= list->size) {
        // If its 0 it could just be a while-looping remove. Keep those silent
        if (!index == 0)
            fprintf(stderr, "Index out of bounds\n");
        return NULL;
    }
    Node current;
    if (index == 0) {
        current = list->head;
        list->head = current->next;
        if (list->head != NULL) {
            list->head->prev = NULL;
        }
    } else if (index == list->size - 1) {
        current = list->tail;
        list->tail = current->prev;
        if (list->tail != NULL) {
            list->tail->next = NULL;
        }
    } else {
        if (list->size - index < index) {
            // Faster to start from the tail
            current = list->tail;
            for (int i = list->size - 1; i > index; i--) {
                current = current->prev;
            }
        } else {
            // Faster to start from the head
            current = list->head;
            for (int i = 0; i < index; i++) {
                current = current->next;
            }
        }
        current->prev->next = current->next;
        current->next->prev = current->prev;
    }
    Data data = current->data;
    free(current);
    list->size--;
    return data;
}

/**
 * Get the size of the list
 * @param list List to get size of
 * @return size of list
*/
int ll_size(List list) {
    return list->size;
}