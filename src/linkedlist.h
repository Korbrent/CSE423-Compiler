#ifndef LINKEDLIST_H
#define LINKEDLIST_H

typedef struct node_t *Node;
typedef struct list_t *List;
typedef void *Data;

struct node_t {
    Data data;
    Node next;
    Node prev;
};

struct list_t {
    Node head;
    Node tail;
    int size;
};

List ll_create();
void ll_destroy(List list);
void ll_add(List list, void *data);
void ll_insert(List list, void *data, int index);
Data ll_get(List list, int index);
Data ll_remove(List list, int index);
int ll_size(List list);

#endif