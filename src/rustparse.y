%{
/**
 * Modified by Korbin Shelley
 * @date: March 03, 2024
 * @file: rustparse.y
 * @brief: This file contains the grammar for the Irony programming language.
 * @version: 0.4.6
 */
/* 


 * Adapted from from the Rust project's deleted parser-lalr.y
 * via the Wayback Machine. Since that grammar was old and
 * Rust changed incompatibly since then, you should test/check
 * everything and trust nothing.

// Copyright 2015 The Rust Project Developers. See the COPYRIGHT
// file at the top-level directory of this distribution and at
// http://rust-lang.org/COPYRIGHT.
//
// Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
// http://www.apache.org/licenses/LICENSE-2.0> or the MIT license
// <LICENSE-MIT or http://opensource.org/licenses/MIT>, at your
// option. This file may not be copied, modified, or distributed
// except according to those terms.

 */
#include "tree.h"
#include "parserRules.h"

#define YYERROR_VERBOSE
// #define YYSTYPE struct node *
extern int yylex();
extern void yyerror(char const *s);
void __yyerror(char *s, int errorCode, int lineno, int returnType);
int getLineNo();
#define yyerror(s) __yyerror(s, yystate, getLineNo(), 2)

%}
%debug

%union {
        struct tree *treeptr;
}

%token<treeptr> TILDE
%token<treeptr> EQUAL
%token<treeptr> DOUBLE_EQUAL
%token<treeptr> BANG
%token<treeptr> NOT_EQUAL
%token<treeptr> LESS_THAN
%token<treeptr> LESS_THAN_EQUAL
%token<treeptr> DOUBLE_LESS_THAN
%token<treeptr> DOUBLE_LESS_THAN_EQUAL
%token<treeptr> GREATER_THAN
%token<treeptr> GREATER_THAN_EQUAL
%token<treeptr> DOUBLE_GREATER_THAN
%token<treeptr> DOUBLE_GREATER_THAN_EQUAL
%token<treeptr> AMPERSAND
%token<treeptr> AMPERSAND_EQUAL
%token<treeptr> DOUBLE_AMPERSAND
%token<treeptr> PIPE
%token<treeptr> PIPE_EQUAL
%token<treeptr> DOUBLE_PIPE
%token<treeptr> CARET
%token<treeptr> CARET_EQUAL
%token<treeptr> PLUS
%token<treeptr> PLUS_EQUAL
%token<treeptr> MINUS
%token<treeptr> MINUS_EQUAL
%token<treeptr> STAR
%token<treeptr> STAR_EQUAL
%token<treeptr> SLASH
%token<treeptr> SLASH_EQUAL
%token<treeptr> PERCENT
%token<treeptr> PERCENT_EQUAL
%token<treeptr> DOT
%token<treeptr> DOUBLE_DOT
%token<treeptr> TRIPLE_DOT
%token<treeptr> DOUBLE_COLON

%token<treeptr> HASH
%token<treeptr> COMMA
%token<treeptr> SEMICOLON
%token<treeptr> COLON
%token<treeptr> QUESTION
%token<treeptr> AT
%token<treeptr> DOLLAR
%token<treeptr> RIGHT_PAREN
%token<treeptr> LEFT_PAREN
%token<treeptr> RIGHT_BRACKET
%token<treeptr> LEFT_BRACKET
%token<treeptr> RIGHT_BRACE
%token<treeptr> LEFT_BRACE


%token<treeptr> ARROW
%token<treeptr> LARROW
%token<treeptr> FAT_ARROW
%token<treeptr> LIT_BYTE
%token<treeptr> CHAR_LITERAL
%token<treeptr> INTEGER_LITERAL
%token<treeptr> FLOAT_LITERAL
%token<treeptr> STRING_LITERAL
%token<treeptr> STRING_LITERAL_RAW
%token<treeptr> LIT_BYTE_STR
%token<treeptr> LIT_BYTE_STR_RAW
%token<treeptr> IDENTIFIER
%token<treeptr> UNDERSCORE
%token<treeptr> LIFETIME

// keywords
%token<treeptr> ABSTRACT
%token<treeptr> ALIGNOF
%token<treeptr> AS
%token<treeptr> BECOME
%token<treeptr> BREAK
%token<treeptr> CATCH
%token<treeptr> CRATE
%token<treeptr> DO
%token<treeptr> ELSE
%token<treeptr> ENUM
%token<treeptr> EXTERN
%token<treeptr> FALSE
%token<treeptr> FINAL
%token<treeptr> FN
%token<treeptr> FOR
%token<treeptr> IF
%token<treeptr> IMPL
%token<treeptr> IN
%token<treeptr> LET
%token<treeptr> LOOP
%token<treeptr> MACRO
%token<treeptr> MATCH
%token<treeptr> MOD
%token<treeptr> MOVE
%token<treeptr> MUT
%token<treeptr> OFFSETOF
%token<treeptr> OVERRIDE
%token<treeptr> PRIV
%token<treeptr> PUB
%token<treeptr> PURE
%token<treeptr> REF
%token<treeptr> RETURN
%token<treeptr> SELF
%token<treeptr> STATIC
%token<treeptr> SIZEOF
%token<treeptr> STRUCT
%token<treeptr> SUPER
%token<treeptr> UNION
%token<treeptr> UNSIZED
%token<treeptr> TRUE
%token<treeptr> TRAIT
%token<treeptr> TYPE
%token<treeptr> UNSAFE
%token<treeptr> VIRTUAL
%token<treeptr> YIELD
%token<treeptr> DEFAULT
%token<treeptr> USE
%token<treeptr> WHILE
%token<treeptr> CONTINUE
%token<treeptr> PROC
%token<treeptr> BOX
%token<treeptr> CONST
%token<treeptr> WHERE
%token<treeptr> TYPEOF
%token<treeptr> INNER_DOC_COMMENT
%token<treeptr> OUTER_DOC_COMMENT

%token<treeptr> SHEBANG
%token<treeptr> SHEBANG_LINE
%token<treeptr> STATIC_LIFETIME

%token LEXICAL_ERROR // Only used by the lexer to indicate an error.

 /*
   Quoting from the Bison manual:

   "Finally, the resolution of conflicts works by comparing the precedence
   of the rule being considered with that of the lookahead token. If the
   token's precedence is higher, the choice is to shift. If the rule's
   precedence is higher, the choice is to reduce. If they have equal
   precedence, the choice is made based on the associativity of that
   precedence level. The verbose output file made by ‘-v’ (see Invoking
   Bison) says how each conflict was resolved"
 */

// We expect no shift/reduce or reduce/reduce conflicts in this grammar;
// all potential ambiguities are scrutinized and eliminated manually.
%expect 0

// fake-precedence symbol to cause '|' bars in lambda context to parse
// at low precedence, permit things like |x| foo = bar, where '=' is
// otherwise lower-precedence than '|'. Also used for proc() to cause
// things like proc() a + b to parse as proc() { a + b }.
%precedence LAMBDA

%precedence SELF

// MUT should be lower precedence than IDENTIFIER so that in the pat rule,
// "& MUT pat" has higher precedence than "binding_mode ident [@ pat]"
%precedence MUT

// IDENTIFIER needs to be lower than LEFT_BRACE so that 'foo {' is shifted when
// trying to decide if we've got a struct-construction expr (esp. in
// contexts like 'if foo { .')
//
// IDENTIFIER also needs to be lower precedence than '<' so that '<' in
// 'foo:bar . <' is shifted (in a trait reference occurring in a
// bounds list), parsing as foo:(bar<baz>) rather than (foo:bar)<baz>.
%precedence IDENTIFIER
 // Put the weak keywords that can be used as idents here as well
%precedence CATCH
%precedence DEFAULT
%precedence UNION

// A couple fake-precedence symbols to use in rules associated with +
// and < in trailing type contexts. These come up when you have a type
// in the RHS of operator-AS, such as "foo as bar<baz>". The "<" there
// has to be shifted so the parser keeps trying to parse a type, even
// though it might well consider reducing the type "bar" and then
// going on to "<" as a subsequent binop. The "+" case is with
// trailing type-bounds ("foo as bar:A+B"), for the same reason.
%precedence SHIFTPLUS

%precedence DOUBLE_COLON
%precedence ARROW COLON

// In where clauses, "for" should have greater precedence when used as
// a higher ranked constraint than when used as the beginning of a
// for_in_type (which is a ty)
%precedence FORTYPE
%precedence FOR

// Binops & unops, and their precedences
%precedence QUESTION
%precedence BOX
%nonassoc DOUBLE_DOT

// RETURN needs to be lower-precedence than tokens that start
// prefix_exprs
%precedence RETURN YIELD

%right EQUAL DOUBLE_LESS_THAN_EQUAL DOUBLE_GREATER_THAN_EQUAL MINUS_EQUAL AMPERSAND_EQUAL PIPE_EQUAL PLUS_EQUAL STAR_EQUAL SLASH_EQUAL CARET_EQUAL PERCENT_EQUAL
%right LARROW
%left DOUBLE_PIPE
%left DOUBLE_AMPERSAND
%left DOUBLE_EQUAL NOT_EQUAL
%left LESS_THAN GREATER_THAN LESS_THAN_EQUAL GREATER_THAN_EQUAL
%left PIPE
%left CARET
%left AMPERSAND
%left DOUBLE_LESS_THAN DOUBLE_GREATER_THAN
%left PLUS MINUS
%precedence AS
%left STAR SLASH PERCENT
%precedence BANG

%precedence LEFT_BRACE LEFT_BRACKET LEFT_PAREN DOT

%precedence RANGE

%start crate

%type <treeptr> crate
%type <treeptr> maybe_shebang
%type <treeptr> maybe_inner_attrs
%type <treeptr> inner_attrs
%type <treeptr> inner_attr
%type <treeptr> maybe_outer_attrs
%type <treeptr> outer_attrs
%type <treeptr> outer_attr
%type <treeptr> meta_item
%type <treeptr> meta_seq
%type <treeptr> maybe_mod_items
%type <treeptr> mod_items
%type <treeptr> attrs_and_vis
%type <treeptr> mod_item
%type <treeptr> item
%type <treeptr> stmt_item
%type <treeptr> item_static
%type <treeptr> item_const
%type <treeptr> item_macro
%type <treeptr> view_item
%type <treeptr> extern_fn_item
%type <treeptr> use_item
%type <treeptr> view_path
%type <treeptr> block_item
%type <treeptr> maybe_ty_ascription
%type <treeptr> maybe_init_expr
%type <treeptr> item_struct
%type <treeptr> struct_decl_args
%type <treeptr> struct_tuple_args
%type <treeptr> struct_decl_fields
%type <treeptr> struct_decl_field
%type <treeptr> struct_tuple_fields
%type <treeptr> struct_tuple_field
%type <treeptr> item_enum
%type <treeptr> enum_defs
%type <treeptr> enum_def
%type <treeptr> enum_args
%type <treeptr> item_union
%type <treeptr> item_mod
%type <treeptr> item_foreign_mod
%type <treeptr> maybe_abi
%type <treeptr> maybe_foreign_items
%type <treeptr> foreign_items
%type <treeptr> foreign_item
%type <treeptr> item_foreign_static
%type <treeptr> item_foreign_fn
%type <treeptr> fn_decl_allow_variadic
%type <treeptr> fn_params_allow_variadic
%type <treeptr> visibility
%type <treeptr> idents_or_self
%type <treeptr> ident_or_self
%type <treeptr> item_type
%type <treeptr> for_sized
%type <treeptr> item_trait
%type <treeptr> maybe_trait_items
%type <treeptr> trait_items
%type <treeptr> trait_item
%type <treeptr> trait_const
%type <treeptr> maybe_const_default
%type <treeptr> trait_type
%type <treeptr> maybe_unsafe
%type <treeptr> maybe_default_maybe_unsafe
%type <treeptr> trait_method
%type <treeptr> type_method
%type <treeptr> method
%type <treeptr> impl_method
%type <treeptr> item_impl
%type <treeptr> maybe_impl_items
%type <treeptr> impl_items
%type <treeptr> impl_item
%type <treeptr> maybe_default
%type <treeptr> impl_const
%type <treeptr> impl_type
%type <treeptr> item_fn
%type <treeptr> item_unsafe_fn
%type <treeptr> fn_decl
%type <treeptr> fn_decl_with_self
%type <treeptr> fn_decl_with_self_allow_anon_params
%type <treeptr> fn_params
%type <treeptr> fn_anon_params
%type <treeptr> fn_params_with_self
%type <treeptr> fn_anon_params_with_self
%type <treeptr> maybe_params
%type <treeptr> params
%type <treeptr> param
%type <treeptr> inferrable_params
%type <treeptr> inferrable_param
%type <treeptr> maybe_comma_params
%type <treeptr> maybe_comma_anon_params
%type <treeptr> maybe_anon_params
%type <treeptr> anon_params
%type <treeptr> anon_param
%type <treeptr> anon_params_allow_variadic_tail
%type <treeptr> named_arg
%type <treeptr> ret_ty
%type <treeptr> generic_params
%type <treeptr> maybe_where_clause
%type <treeptr> where_clause
%type <treeptr> where_predicates
%type <treeptr> where_predicate
%type <treeptr> maybe_for_lifetimes
%type <treeptr> ty_params
%type <treeptr> path_no_types_allowed
%type <treeptr> path_generic_args_without_colons
%type <treeptr> generic_args
%type <treeptr> generic_values
%type <treeptr> maybe_ty_sums_and_or_bindings
%type <treeptr> maybe_bindings

%type <treeptr> pat
%type <treeptr> pats_or
%type <treeptr> binding_mode
%type <treeptr> lit_or_path
%type <treeptr> pat_field
%type <treeptr> pat_fields
%type <treeptr> pat_struct
%type <treeptr> pat_tup
%type <treeptr> pat_tup_elts
%type <treeptr> pat_vec
%type <treeptr> pat_vec_elts

%type <treeptr> ty
%type <treeptr> ty_prim
%type <treeptr> ty_bare_fn
%type <treeptr> ty_fn_decl
%type <treeptr> ty_closure
%type <treeptr> for_in_type
%type <treeptr> for_in_type_suffix
%type <treeptr> maybe_mut
%type <treeptr> maybe_mut_or_const
%type <treeptr> ty_qualified_path_and_generic_values
%type <treeptr> ty_qualified_path
%type <treeptr> maybe_ty_sums
%type <treeptr> ty_sums
%type <treeptr> ty_sum
%type <treeptr> ty_sum_elt
%type <treeptr> ty_prim_sum
%type <treeptr> ty_prim_sum_elt
%type <treeptr> maybe_ty_param_bounds
%type <treeptr> ty_param_bounds
%type <treeptr> boundseq
%type <treeptr> polybound
%type <treeptr> bindings
%type <treeptr> binding
%type <treeptr> ty_param
%type <treeptr> maybe_bounds
%type <treeptr> bounds
%type <treeptr> bound
%type <treeptr> maybe_ltbounds
%type <treeptr> ltbounds
%type <treeptr> maybe_ty_default
%type <treeptr> maybe_lifetimes
%type <treeptr> lifetimes
%type <treeptr> lifetime_and_bounds
%type <treeptr> lifetime
%type <treeptr> trait_ref

%type <treeptr> inner_attrs_and_block
%type <treeptr> block
%type <treeptr> maybe_stmts
%type <treeptr> stmts
%type <treeptr> stmt
%type <treeptr> maybe_exprs
%type <treeptr> maybe_expr
%type <treeptr> exprs
%type <treeptr> path_expr
%type <treeptr> path_generic_args_with_colons
%type <treeptr> macro_expr
%type <treeptr> nonblock_expr
%type <treeptr> expr
%type <treeptr> expr_nostruct
%type <treeptr> nonblock_prefix_expr_nostruct
%type <treeptr> nonblock_prefix_expr
%type <treeptr> expr_qualified_path
%type <treeptr> maybe_qpath_params
%type <treeptr> maybe_as_trait_ref
%type <treeptr> lambda_expr
%type <treeptr> lambda_expr_no_first_bar
%type <treeptr> lambda_expr_nostruct
%type <treeptr> lambda_expr_nostruct_no_first_bar
%type <treeptr> vec_expr
%type <treeptr> struct_expr_fields
%type <treeptr> maybe_field_inits
%type <treeptr> field_inits
%type <treeptr> field_init
%type <treeptr> default_field_init
%type <treeptr> block_expr
%type <treeptr> full_block_expr
%type <treeptr> block_expr_dot
%type <treeptr> expr_match
%type <treeptr> match_clauses
%type <treeptr> match_clause
%type <treeptr> nonblock_match_clause
%type <treeptr> block_match_clause
%type <treeptr> maybe_guard
%type <treeptr> expr_if
%type <treeptr> expr_if_let
%type <treeptr> block_or_if
%type <treeptr> expr_while
%type <treeptr> expr_while_let
%type <treeptr> expr_loop
%type <treeptr> expr_for
%type <treeptr> maybe_label
%type <treeptr> let

%type <treeptr> lit
%type <treeptr> str
%type <treeptr> maybe_ident
%type <treeptr> ident
%type <treeptr> unpaired_token
%type <treeptr> token_trees
%type <treeptr> token_tree
%type <treeptr> delimited_token_trees
%type <treeptr> parens_delimited_token_trees
%type <treeptr> braces_delimited_token_trees
%type <treeptr> brackets_delimited_token_trees

%%

////////////////////////////////////////////////////////////////////////
// Part 1: Items and attributes
////////////////////////////////////////////////////////////////////////

crate   : maybe_shebang inner_attrs maybe_mod_items     { setTreeRoot(treealloc(CRATE_R, "crate", 3, $1, $2, $3)); }
        | maybe_shebang maybe_mod_items                 { setTreeRoot(treealloc(CRATE_R, "crate", 2, $1, $2)); }
        ;

maybe_shebang : SHEBANG_LINE            { $$ = $1; }
        | %empty                        { $$ = NULL; }
        ;

maybe_inner_attrs : inner_attrs         { $$ = $1; }
        | %empty                        { $$ = NULL;}
        ;

inner_attrs : inner_attr                { $$ = $1; }
        | inner_attrs inner_attr        { $$ = treealloc(INNER_ATTRS_R, "inner_attrs", 2, $1, $2); }
        ;

inner_attr : SHEBANG LEFT_BRACKET meta_item RIGHT_BRACKET       { $$ = treealloc(INNER_ATTR_R, "inner_attr", 4, $1, $2, $3, $4); }
        | INNER_DOC_COMMENT                                     { $$ = $1; }
        ;

maybe_outer_attrs : outer_attrs         { $$ = $1; }
        | %empty                        { $$ = NULL; }
        ;

outer_attrs : outer_attr                { $$ = $1; }
        | outer_attrs outer_attr        { $$ = treealloc(OUTER_ATTRS_R, "outer_attrs", 2, $1, $2); }
        ;

outer_attr : HASH LEFT_BRACKET meta_item RIGHT_BRACKET  { $$ = treealloc(OUTER_ATTR_R, "outer_attr", 4, $1, $2, $3, $4); }
        | OUTER_DOC_COMMENT                             { $$ = $1; }
        ;

meta_item : ident                                       { $$ = $1; }
        | ident EQUAL lit                               { $$ = treealloc(META_ITEM_R, "meta_item", 3, $1, $2, $3); }
        | ident LEFT_PAREN meta_seq RIGHT_PAREN         { $$ = treealloc(META_ITEM_R, "meta_item", 4, $1, $2, $3, $4); }
        | ident LEFT_PAREN meta_seq COMMA RIGHT_PAREN   { $$ = treealloc(META_ITEM_R, "meta_item", 5, $1, $2, $3, $4, $5); }
        ;

meta_seq : %empty                       { $$ = NULL; }
        | meta_item                     { $$ = $1; }
        | meta_seq COMMA meta_item      { $$ = treealloc(META_SEQ_R, "meta_seq", 3, $1, $2, $3); }
        ;

maybe_mod_items : mod_items             { $$ = $1; }
        | %empty                        { $$ = NULL; }
        ;

mod_items : mod_item                    { $$ = $1; }
        | mod_items mod_item            { $$ = treealloc(MOD_ITEMS_R, "mod_items", 2, $1, $2); }
        ;

attrs_and_vis : maybe_outer_attrs visibility { $$ = treealloc(ATTRS_AND_VIS_R, "attrs_and_vis", 2, $1, $2); }
        ;

mod_item : attrs_and_vis item           { $$ = treealloc(MOD_ITEM_R, "mod_item", 2, $1, $2); }
        ;

// items that can appear outside of a fn block
item : stmt_item                        { $$ = $1; }
        | item_macro                    { $$ = $1; }
        ;

// items that can appear in "stmts"
stmt_item : item_static                 { $$ = $1; }
        | item_const                    { $$ = $1; }
        | item_type                     { $$ = $1; }
        | block_item                    { $$ = $1; }
        | view_item                     { $$ = $1; }
        ;

item_static : STATIC ident COLON ty EQUAL expr SEMICOLON  { $$ = treealloc(ITEM_STATIC_R, "item_static", 7, $1, $2, $3, $4, $5, $6, $7); }
        | STATIC MUT ident COLON ty EQUAL expr SEMICOLON  { $$ = treealloc(ITEM_STATIC_R, "item_static", 8, $1, $2, $3, $4, $5, $6, $7, $8); }
        ;

item_const : CONST ident COLON ty EQUAL expr SEMICOLON    { $$ = treealloc(ITEM_CONST_R, "item_const", 7, $1, $2, $3, $4, $5, $6, $7); }
        ;

item_macro : path_expr BANG maybe_ident parens_delimited_token_trees SEMICOLON  { $$ = treealloc(ITEM_MACRO_R, "item_macro", 5, $1, $2, $3, $4, $5); }
        | path_expr BANG maybe_ident braces_delimited_token_trees               { $$ = treealloc(ITEM_MACRO_R, "item_macro", 4, $1, $2, $3, $4); }
        | path_expr BANG maybe_ident brackets_delimited_token_trees SEMICOLON   { $$ = treealloc(ITEM_MACRO_R, "item_macro", 5, $1, $2, $3, $4, $5); }
        ;

view_item : use_item                    { $$ = $1; }
        | extern_fn_item                { $$ = $1; }
        | EXTERN CRATE ident SEMICOLON  { $$ = treealloc(VIEW_ITEM_R, "view_item", 4, $1, $2, $3, $4); }
        | EXTERN CRATE ident AS ident SEMICOLON             { $$ = treealloc(VIEW_ITEM_R, "view_item", 6, $1, $2, $3, $4, $5, $6); }
        ;

extern_fn_item : EXTERN maybe_abi item_fn       { $$ = treealloc(EXTERN_FN_ITEM_R, "extern_fn_item", 3, $1, $2, $3); }
        ;

use_item : USE view_path SEMICOLON              { $$ = treealloc(USE_ITEM_R, "use_item", 3, $1, $2, $3); }
        ;

view_path : path_no_types_allowed       { $$ = $1; }
        | path_no_types_allowed DOUBLE_COLON LEFT_BRACE                RIGHT_BRACE     { $$ = treealloc(VIEW_PATH_R, "view_path", 4, $1, $2, $3, $4); }
        |                       DOUBLE_COLON LEFT_BRACE                RIGHT_BRACE     { $$ = treealloc(VIEW_PATH_R, "view_path", 3, $1, $2, $3); }
        | path_no_types_allowed DOUBLE_COLON LEFT_BRACE idents_or_self RIGHT_BRACE     { $$ = treealloc(VIEW_PATH_R, "view_path", 5, $1, $2, $3, $4, $5); }
        |                       DOUBLE_COLON LEFT_BRACE idents_or_self RIGHT_BRACE     { $$ = treealloc(VIEW_PATH_R, "view_path", 4, $1, $2, $3, $4); }
        | path_no_types_allowed DOUBLE_COLON LEFT_BRACE idents_or_self COMMA RIGHT_BRACE { $$ = treealloc(VIEW_PATH_R, "view_path", 6, $1, $2, $3, $4, $5, $6); }
        |                       DOUBLE_COLON LEFT_BRACE idents_or_self COMMA RIGHT_BRACE { $$ = treealloc(VIEW_PATH_R, "view_path", 5, $1, $2, $3, $4, $5); }
        | path_no_types_allowed DOUBLE_COLON STAR                                       { $$ = treealloc(VIEW_PATH_R, "view_path", 3, $1, $2, $3); }
        |                       DOUBLE_COLON STAR                                       { $$ = treealloc(VIEW_PATH_R, "view_path", 2, $1, $2); }
        |                               STAR                                            { $$ = $1; }
        |                               LEFT_BRACE                RIGHT_BRACE           { $$ = treealloc(VIEW_PATH_R, "view_path", 2, $1, $2); }
        |                               LEFT_BRACE idents_or_self RIGHT_BRACE           { $$ = treealloc(VIEW_PATH_R, "view_path", 3, $1, $2, $3); }
        |                               LEFT_BRACE idents_or_self COMMA RIGHT_BRACE     { $$ = treealloc(VIEW_PATH_R, "view_path", 4, $1, $2, $3, $4); }
        | path_no_types_allowed AS ident                                                { $$ = treealloc(VIEW_PATH_R, "view_path", 3, $1, $2, $3); }
        ;

block_item : item_fn            { $$ = $1; }
        | item_unsafe_fn        { $$ = $1; }
        | item_mod              { $$ = $1; }
        | item_foreign_mod      { $$ = $1; }
        | item_struct           { $$ = $1; }
        | item_enum             { $$ = $1; }
        | item_union            { $$ = $1; }
        | item_trait            { $$ = $1; }
        | item_impl             { $$ = $1; }
        ;

maybe_ty_ascription : COLON ty_sum      { $$ = treealloc(MAYBE_TY_ASCRIPTION_R, "maybe_ty_ascription", 2, $1, $2); }
        | %empty                        { $$ = NULL; }
        ;

maybe_init_expr : EQUAL expr    { $$ = treealloc(MAYBE_INIT_EXPR_R, "maybe_init_expr", 2, $1, $2); }
        | %empty                { $$ = NULL; }
        ;

// structs
item_struct : STRUCT ident generic_params maybe_where_clause struct_decl_args        { $$ = treealloc(ITEM_STRUCT_R, "item_struct", 5, $1, $2, $3, $4, $5); }
        | STRUCT ident generic_params struct_tuple_args maybe_where_clause SEMICOLON { $$ = treealloc(ITEM_STRUCT_R, "item_struct", 6, $1, $2, $3, $4, $5, $6); }
        | STRUCT ident generic_params maybe_where_clause SEMICOLON                   { $$ = treealloc(ITEM_STRUCT_R, "item_struct", 5, $1, $2, $3, $4, $5); }
        ;

struct_decl_args : LEFT_BRACE struct_decl_fields RIGHT_BRACE    { $$ = treealloc(STRUCT_DECL_ARGS_R, "struct_decl_args", 3, $1, $2, $3); }
        | LEFT_BRACE struct_decl_fields COMMA RIGHT_BRACE       { $$ = treealloc(STRUCT_DECL_ARGS_R, "struct_decl_args", 4, $1, $2, $3, $4); }
        ;

struct_tuple_args : LEFT_PAREN struct_tuple_fields RIGHT_PAREN  { $$ = treealloc(STRUCT_TUPLE_ARGS_R, "struct_tuple_args", 3, $1, $2, $3); }
        | LEFT_PAREN struct_tuple_fields COMMA RIGHT_PAREN      { $$ = treealloc(STRUCT_TUPLE_ARGS_R, "struct_tuple_args", 4, $1, $2, $3, $4); }
        ;

struct_decl_fields : struct_decl_field                          { $$ = $1; }
        | struct_decl_fields COMMA struct_decl_field            { $$ = treealloc(STRUCT_DECL_FIELDS_R, "struct_decl_fields", 3, $1, $2, $3); }
        | %empty                                                { $$ = NULL; }
        ;

struct_decl_field : attrs_and_vis ident COLON ty_sum            { $$ = treealloc(STRUCT_DECL_FIELD_R, "struct_decl_field", 4, $1, $2, $3, $4); }
        ;

struct_tuple_fields : struct_tuple_field                { $$ = $1; }
        | struct_tuple_fields COMMA struct_tuple_field  { $$ = treealloc(STRUCT_TUPLE_FIELDS_R, "struct_tuple_fields", 3, $1, $2, $3); }
        | %empty                                      { $$ = NULL; }
        ;

struct_tuple_field : attrs_and_vis ty_sum             { $$ = treealloc(STRUCT_TUPLE_FIELD_R, "struct_tuple_field", 2, $1, $2); }
        ;

// enums
item_enum : ENUM ident generic_params maybe_where_clause LEFT_BRACE enum_defs RIGHT_BRACE { $$ = treealloc(ITEM_ENUM_R, "item_enum", 7, $1, $2, $3, $4, $5, $6, $7); }
        | ENUM ident generic_params maybe_where_clause LEFT_BRACE enum_defs COMMA RIGHT_BRACE { $$ = treealloc(ITEM_ENUM_R, "item_enum", 8, $1, $2, $3, $4, $5, $6, $7, $8); }
        ;

enum_defs : enum_def                            { $$ = $1;}
        | enum_defs COMMA enum_def              { $$ = treealloc(ENUM_DEFS_R, "enum_defs", 3, $1, $2, $3); }
        | %empty                                { $$ = NULL; }
        ;

enum_def : attrs_and_vis ident enum_args        { $$ = treealloc(ENUM_DEF_R, "enum_def", 3, $1, $2, $3); }
        ;

enum_args : LEFT_BRACE struct_decl_fields RIGHT_BRACE           { $$ = treealloc(ENUM_ARGS_R, "enum_args", 3, $1, $2, $3); }
        | LEFT_BRACE struct_decl_fields COMMA RIGHT_BRACE       { $$ = treealloc(ENUM_ARGS_R, "enum_args", 4, $1, $2, $3, $4); }
        | LEFT_PAREN maybe_ty_sums RIGHT_PAREN                  { $$ = treealloc(ENUM_ARGS_R, "enum_args", 3, $1, $2, $3); }
        | EQUAL expr                                            { $$ = treealloc(ENUM_ARGS_R, "enum_args", 2, $1, $2); }
        | %empty                                                { $$ = NULL; }
        ;

// unions
item_union : UNION ident generic_params maybe_where_clause LEFT_BRACE struct_decl_fields RIGHT_BRACE    { $$ = treealloc(ITEM_UNION_R, "item_union", 7, $1, $2, $3, $4, $5, $6, $7); }
        | UNION ident generic_params maybe_where_clause LEFT_BRACE struct_decl_fields COMMA RIGHT_BRACE { $$ = treealloc(ITEM_UNION_R, "item_union", 8, $1, $2, $3, $4, $5, $6, $7, $8); }
        ;

item_mod : MOD ident SEMICOLON                                          { $$ = treealloc(ITEM_MOD_R, "item_mod", 3, $1, $2, $3); }
        | MOD ident LEFT_BRACE maybe_mod_items RIGHT_BRACE              { $$ = treealloc(ITEM_MOD_R, "item_mod", 5, $1, $2, $3, $4, $5); }
        | MOD ident LEFT_BRACE inner_attrs maybe_mod_items RIGHT_BRACE  { $$ = treealloc(ITEM_MOD_R, "item_mod", 6, $1, $2, $3, $4, $5, $6); }
        ;

item_foreign_mod : EXTERN maybe_abi LEFT_BRACE maybe_foreign_items RIGHT_BRACE { $$ = treealloc(ITEM_FOREIGN_MOD_R, "item_foreign_mod", 5, $1, $2, $3, $4, $5); }
        | EXTERN maybe_abi LEFT_BRACE inner_attrs maybe_foreign_items RIGHT_BRACE { $$ = treealloc(ITEM_FOREIGN_MOD_R, "item_foreign_mod", 6, $1, $2, $3, $4, $5, $6); }
        ;

maybe_abi : str         { $$ = $1; }
        | %empty        { $$ = NULL; }
        ;

maybe_foreign_items : foreign_items { $$ = $1; }
        | %empty        { $$ = NULL; }
        ;

foreign_items : foreign_item            { $$ = $1; }
        | foreign_items foreign_item    { $$ = treealloc(FOREIGN_ITEMS_R, "foreign_items", 2, $1, $2); }
        ;

foreign_item : attrs_and_vis STATIC item_foreign_static { $$ = treealloc(FOREIGN_ITEM_R, "foreign_item", 3, $1, $2, $3); }
        | attrs_and_vis item_foreign_fn                 { $$ = treealloc(FOREIGN_ITEM_R, "foreign_item", 2, $1, $2); }
        | attrs_and_vis UNSAFE item_foreign_fn          { $$ = treealloc(FOREIGN_ITEM_R, "foreign_item", 3, $1, $2, $3); }
        ;

item_foreign_static
        : maybe_mut ident COLON ty SEMICOLON            { $$ = treealloc(ITEM_FOREIGN_STATIC_R, "item_foreign_static", 5, $1, $2, $3, $4, $5); }
        ;

item_foreign_fn
        : FN ident generic_params fn_decl_allow_variadic maybe_where_clause SEMICOLON
        { $$ = treealloc(ITEM_FOREIGN_FN_R, "item_foreign_fn", 6, $1, $2, $3, $4, $5, $6); }
        ;

fn_decl_allow_variadic : fn_params_allow_variadic ret_ty { $$ = treealloc(FN_DECL_ALLOW_VARIADIC_R, "fn_decl_allow_variadic", 2, $1, $2); }
        ;

fn_params_allow_variadic : LEFT_PAREN RIGHT_PAREN               { $$ = treealloc(FN_PARAMS_ALLOW_VARIADIC_R, "fn_params_allow_variadic", 2, $1, $2); }
        | LEFT_PAREN params RIGHT_PAREN                         { $$ = treealloc(FN_PARAMS_ALLOW_VARIADIC_R, "fn_params_allow_variadic", 3, $1, $2, $3); }
        | LEFT_PAREN params COMMA RIGHT_PAREN                   { $$ = treealloc(FN_PARAMS_ALLOW_VARIADIC_R, "fn_params_allow_variadic", 4, $1, $2, $3, $4); }
        | LEFT_PAREN params COMMA TRIPLE_DOT RIGHT_PAREN        { $$ = treealloc(FN_PARAMS_ALLOW_VARIADIC_R, "fn_params_allow_variadic", 5, $1, $2, $3, $4, $5); }
        ;

visibility : PUB        { $$ = $1; }
        | %empty        { $$ = NULL; }
        ;

idents_or_self : ident_or_self                  { $$ = $1; }
        | idents_or_self AS ident               { $$ = treealloc(IDENTS_OR_SELF_R, "idents_or_self", 3, $1, $2, $3); }
        | idents_or_self COMMA ident_or_self    { $$ = treealloc(IDENTS_OR_SELF_R, "idents_or_self", 3, $1, $2, $3); }
        ;

ident_or_self : ident                           { $$ = $1; }
        | SELF                                  { $$ = $1; }
        ;

item_type : TYPE ident generic_params maybe_where_clause EQUAL ty_sum SEMICOLON  { $$ = treealloc(ITEM_TYPE_R, "item_type", 7, $1, $2, $3, $4, $5, $6, $7); }
        ;

for_sized : FOR QUESTION ident { $$ = treealloc(FOR_SIZED_R, "for_sized", 3, $1, $2, $3); }
        | FOR ident QUESTION { $$ = treealloc(FOR_SIZED_R, "for_sized", 3, $1, $2, $3); }
        | %empty        { $$ = NULL; }
        ;

item_trait : maybe_unsafe TRAIT ident generic_params for_sized
             maybe_ty_param_bounds maybe_where_clause LEFT_BRACE maybe_trait_items RIGHT_BRACE
          {
                $$ = treealloc(ITEM_TRAIT_R, "item_trait", 10, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10);
          }
        ;

maybe_trait_items : trait_items { $$ = $1; }
        | %empty { $$ = NULL; }
        ;

trait_items : trait_item               { $$ = $1; }
        | trait_items trait_item       { $$ = treealloc(TRAIT_ITEMS_R, "trait_items", 2, $1, $2);}
        ;

trait_item : trait_const        { $$ = $1; }
        | trait_type            { $$ = $1; }
        | trait_method          { $$ = $1; }
        | maybe_outer_attrs item_macro { $$ = treealloc(TRAIT_ITEM_R, "trait_item", 2, $1, $2); }
        ;

trait_const : maybe_outer_attrs CONST ident maybe_ty_ascription
              maybe_const_default SEMICOLON { $$ = treealloc(TRAIT_CONST_R, "trait_const", 6, $1, $2, $3, $4, $5, $6); }
        ;

maybe_const_default : EQUAL expr { $$ = treealloc(MAYBE_CONST_DEFAULT_R, "maybe_const_default", 2, $1, $2); }
        | %empty   { $$ = NULL;}
        ;

trait_type : maybe_outer_attrs TYPE ty_param SEMICOLON { $$ = treealloc(TRAIT_TYPE_R, "trait_type", 4, $1, $2, $3, $4); }
        ;

maybe_unsafe : UNSAFE { $$ = $1; }
        | %empty { $$ = NULL;}
        ;

maybe_default_maybe_unsafe : DEFAULT UNSAFE { $$ = treealloc(MAYBE_DEFAULT_MAYBE_UNSAFE_R, "maybe_default_maybe_unsafe", 2, $1, $2); }
        | DEFAULT        { $$ = $1; }
        |         UNSAFE { $$ = $1; }
        | %empty { $$ = NULL; }
        ;

trait_method : type_method { $$ = $1; }
        | method      { $$ = $1; }
        ;

type_method : maybe_outer_attrs maybe_unsafe FN ident generic_params
              fn_decl_with_self_allow_anon_params maybe_where_clause SEMICOLON
          {
                $$ = treealloc(TYPE_METHOD_R, "type_method", 8, $1, $2, $3, $4, $5, $6, $7, $8);
          }
        | maybe_outer_attrs CONST maybe_unsafe FN ident generic_params
          fn_decl_with_self_allow_anon_params maybe_where_clause SEMICOLON {
                $$ = treealloc(TYPE_METHOD_R, "type_method", 9, $1, $2, $3, $4, $5, $6, $7, $8, $9);
          }
        | maybe_outer_attrs maybe_unsafe EXTERN maybe_abi FN ident
          generic_params fn_decl_with_self_allow_anon_params
           maybe_where_clause SEMICOLON {
                $$ = treealloc(TYPE_METHOD_R, "type_method", 10, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10);
          }
        ;

method : maybe_outer_attrs maybe_unsafe FN ident generic_params
         fn_decl_with_self_allow_anon_params maybe_where_clause
          inner_attrs_and_block {
                $$ = treealloc(METHOD_R, "method", 8, $1, $2, $3, $4, $5, $6, $7, $8);
         }
        | maybe_outer_attrs CONST maybe_unsafe FN ident generic_params
          fn_decl_with_self_allow_anon_params maybe_where_clause
          inner_attrs_and_block {
                $$ = treealloc(METHOD_R, "method", 9, $1, $2, $3, $4, $5, $6, $7, $8, $9);
          }
        | maybe_outer_attrs maybe_unsafe EXTERN maybe_abi FN ident
          generic_params fn_decl_with_self_allow_anon_params
          maybe_where_clause inner_attrs_and_block {
                $$ = treealloc(METHOD_R, "method", 10, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10);
          }
        ;

impl_method : attrs_and_vis maybe_default maybe_unsafe FN ident generic_params
              fn_decl_with_self maybe_where_clause inner_attrs_and_block {
                $$ = treealloc(IMPL_METHOD_R, "impl_method", 8, $1, $2, $3, $4, $5, $6, $7, $8);
          }
        | attrs_and_vis maybe_default CONST maybe_unsafe FN ident
          generic_params fn_decl_with_self maybe_where_clause
          inner_attrs_and_block {
                $$ = treealloc(IMPL_METHOD_R, "impl_method", 10, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10);
          }
        | attrs_and_vis maybe_default maybe_unsafe EXTERN maybe_abi FN ident
          generic_params fn_decl_with_self maybe_where_clause
          inner_attrs_and_block {
                $$ = treealloc(IMPL_METHOD_R, "impl_method", 11, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11);
          }
        ;

// There are two forms of impl:
//
// impl (<...>)? TY { ... }
// impl (<...>)? TRAIT for TY { ... }
//
// Unfortunately since TY can begin with '<' itself -- as part of a
// TyQualifiedPath type -- there's an s/r conflict when we see '<' after IMPL:
// should we reduce one of the early rules of TY (such as maybe_once)
// or shall we continue shifting into the generic_params list for the
// impl?
//
// The production parser disambiguates a different case here by
// permitting / requiring the user to provide parens around types when
// they are ambiguous with traits. We do the same here, regrettably,
// by splitting ty into ty and ty_prim.
item_impl : maybe_default_maybe_unsafe IMPL generic_params ty_prim_sum
             maybe_where_clause LEFT_BRACE maybe_inner_attrs maybe_impl_items RIGHT_BRACE {
                $$ = treealloc(ITEM_IMPL_R, "item_impl", 9, $1, $2, $3, $4, $5, $6, $7, $8, $9);
          }
        | maybe_default_maybe_unsafe IMPL generic_params LEFT_PAREN ty RIGHT_PAREN
          maybe_where_clause LEFT_BRACE maybe_inner_attrs maybe_impl_items RIGHT_BRACE {
                $$ = treealloc(ITEM_IMPL_R, "item_impl", 11, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11);
          }
        | maybe_default_maybe_unsafe IMPL generic_params trait_ref FOR ty_sum maybe_where_clause LEFT_BRACE maybe_inner_attrs maybe_impl_items RIGHT_BRACE {
                $$ = treealloc(ITEM_IMPL_R, "item_impl", 11, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11);
          }
        | maybe_default_maybe_unsafe IMPL generic_params BANG trait_ref FOR
           ty_sum maybe_where_clause LEFT_BRACE maybe_inner_attrs maybe_impl_items RIGHT_BRACE
          {
                $$ = treealloc(ITEM_IMPL_R, "item_impl", 12, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12);
          }
        | maybe_default_maybe_unsafe IMPL generic_params trait_ref FOR DOUBLE_DOT
          LEFT_BRACE RIGHT_BRACE {
                $$ = treealloc(ITEM_IMPL_R, "item_impl", 8, $1, $2, $3, $4, $5, $6, $7, $8);
          }
        | maybe_default_maybe_unsafe IMPL generic_params BANG trait_ref FOR
          DOUBLE_DOT LEFT_BRACE RIGHT_BRACE {
                $$ = treealloc(ITEM_IMPL_R, "item_impl", 9, $1, $2, $3, $4, $5, $6, $7, $8, $9);
          }
        ;

maybe_impl_items : impl_items   { $$ = $1; }
        | %empty                { $$ = NULL; }
        ;

impl_items : impl_item                  { $$ = $1; }
        | impl_item impl_items          { $$ = treealloc(IMPL_ITEMS_R, "impl_items", 2, $1, $2); }
        ;

impl_item : impl_method                 { $$ = $1; }
        | attrs_and_vis item_macro      { $$ = treealloc(IMPL_ITEM_R, "impl_item", 2, $1, $2); }
        | impl_const                    { $$ = $1; }
        | impl_type                     { $$ = $1; }
        ;

maybe_default : DEFAULT                 { $$ = $1; }
        | %empty        { $$ = NULL; }
        ;

impl_const : attrs_and_vis maybe_default item_const { $$ = treealloc(IMPL_CONST_R, "impl_const", 3, $1, $2, $3); }
        ;

impl_type : attrs_and_vis maybe_default TYPE ident generic_params
            EQUAL ty_sum SEMICOLON  { $$ = treealloc(IMPL_TYPE_R, "impl_type", 8, $1, $2, $3, $4, $5, $6, $7, $8); }
        ;

item_fn : FN ident generic_params fn_decl maybe_where_clause
          inner_attrs_and_block {
                $$ = treealloc(ITEM_FN_R, "item_fn", 6, $1, $2, $3, $4, $5, $6);
          }
        | CONST FN ident generic_params fn_decl maybe_where_clause
           inner_attrs_and_block {
                $$ = treealloc(ITEM_FN_R, "item_fn", 7, $1, $2, $3, $4, $5, $6, $7);
          }
        ;

item_unsafe_fn : UNSAFE FN ident generic_params fn_decl maybe_where_clause
                 inner_attrs_and_block {
                $$ = treealloc(ITEM_UNSAFE_FN_R, "item_unsafe_fn", 7, $1, $2, $3, $4, $5, $6, $7);
          }
        | CONST UNSAFE FN ident generic_params fn_decl maybe_where_clause
          inner_attrs_and_block {
                $$ = treealloc(ITEM_UNSAFE_FN_R, "item_unsafe_fn", 8, $1, $2, $3, $4, $5, $6, $7, $8);
          }
        | UNSAFE EXTERN maybe_abi FN ident generic_params fn_decl
           maybe_where_clause inner_attrs_and_block {
                $$ = treealloc(ITEM_UNSAFE_FN_R, "item_unsafe_fn", 9, $1, $2, $3, $4, $5, $6, $7, $8, $9);
          }
        ;

fn_decl : fn_params ret_ty   { $$ = treealloc(FN_DECL_R, "fn_decl", 2, $1, $2); }
        ;

fn_decl_with_self : fn_params_with_self ret_ty   { $$ = treealloc(FN_DECL_WITH_SELF_R, "fn_decl_with_self", 2, $1, $2); }
        ;

fn_decl_with_self_allow_anon_params : fn_anon_params_with_self ret_ty   { $$ = treealloc(FN_DECL_WITH_SELF_ALLOW_ANON_PARAMS_R, "fn_decl_with_self_allow_anon_params", 2, $1, $2); }
        ;

fn_params : LEFT_PAREN maybe_params RIGHT_PAREN  { $$ = treealloc(FN_PARAMS_R, "fn_params", 3, $1, $2, $3); }
        ;

fn_anon_params : LEFT_PAREN anon_param anon_params_allow_variadic_tail RIGHT_PAREN { $$ = treealloc(FN_ANON_PARAMS_R, "fn_anon_params", 4, $1, $2, $3, $4); }
        | LEFT_PAREN RIGHT_PAREN                                            { $$ = treealloc(FN_ANON_PARAMS_R, "fn_anon_params", 2, $1, $2); }
        ;

fn_params_with_self : LEFT_PAREN maybe_mut SELF maybe_ty_ascription
        	       maybe_comma_params RIGHT_PAREN              { $$ = treealloc(FN_PARAMS_WITH_SELF_R, "fn_params_with_self", 6, $1, $2, $3, $4, $5, $6); }
        | LEFT_PAREN AMPERSAND maybe_mut SELF maybe_ty_ascription maybe_comma_params RIGHT_PAREN {
                $$ = treealloc(FN_PARAMS_WITH_SELF_R, "fn_params_with_self", 7, $1, $2, $3, $4, $5, $6, $7);
          }
        | LEFT_PAREN AMPERSAND lifetime maybe_mut SELF maybe_ty_ascription
           maybe_comma_params RIGHT_PAREN { $$ = treealloc(FN_PARAMS_WITH_SELF_R, "fn_params_with_self", 8, $1, $2, $3, $4, $5, $6, $7, $8); }
        | LEFT_PAREN maybe_params RIGHT_PAREN    { $$ = treealloc(FN_PARAMS_WITH_SELF_R, "fn_params_with_self", 3, $1, $2, $3); }
        ;

fn_anon_params_with_self : LEFT_PAREN maybe_mut SELF maybe_ty_ascription
        maybe_comma_anon_params RIGHT_PAREN              { $$ = treealloc(FN_ANON_PARAMS_WITH_SELF_R, "fn_anon_params_with_self", 6, $1, $2, $3, $4, $5, $6); }
        | LEFT_PAREN AMPERSAND maybe_mut SELF maybe_ty_ascription maybe_comma_anon_params
          RIGHT_PAREN          { $$ = treealloc(FN_ANON_PARAMS_WITH_SELF_R, "fn_anon_params_with_self", 7, $1, $2, $3, $4, $5, $6, $7); }
        | LEFT_PAREN AMPERSAND lifetime maybe_mut SELF maybe_ty_ascription
          maybe_comma_anon_params RIGHT_PAREN { $$ = treealloc(FN_ANON_PARAMS_WITH_SELF_R, "fn_anon_params_with_self", 8, $1, $2, $3, $4, $5, $6, $7, $8); }
        | LEFT_PAREN maybe_anon_params RIGHT_PAREN   { $$ = treealloc(FN_ANON_PARAMS_WITH_SELF_R, "fn_anon_params_with_self", 3, $1, $2, $3); }
        ;

maybe_params : params { $$ = $1; }
        | params COMMA { $$ = treealloc(MAYBE_PARAMS_R, "maybe_params", 2, $1, $2); }
        | %empty  { $$ = NULL; }
        ;

params  : param                { $$ = $1; }
        | params COMMA param     { $$ = treealloc(PARAMS_R, "params", 3, $1, $2, $3); }
        ;

param   : pat COLON ty_sum   { $$ = treealloc(PARAM_R, "param", 3, $1, $2, $3); }
        ;

inferrable_params : inferrable_param                       { $$ = $1; }
        | inferrable_params COMMA inferrable_param { $$ = treealloc(INFERRABLE_PARAMS_R, "inferrable_params", 3, $1, $2, $3); }
        ;

inferrable_param : pat maybe_ty_ascription { $$ = treealloc(INFERRABLE_PARAM_R, "inferrable_param", 2, $1, $2); }
        ;

maybe_comma_params : COMMA      { $$ = $1; }
        | COMMA params          { $$ = treealloc(MAYBE_COMMA_PARAMS_R, "maybe_comma_params", 2, $1, $2); }
        | COMMA params COMMA    { $$ = treealloc(MAYBE_COMMA_PARAMS_R, "maybe_comma_params", 3, $1, $2, $3); }
        | %empty                { $$ = NULL; }
        ;

maybe_comma_anon_params : COMMA                 { $$ = $1; }
        | COMMA anon_params                     { $$ = treealloc(MAYBE_COMMA_ANON_PARAMS_R, "maybe_comma_anon_params", 2, $1, $2); }
        | COMMA anon_params COMMA               { $$ = treealloc(MAYBE_COMMA_ANON_PARAMS_R, "maybe_comma_anon_params", 3, $1, $2, $3); }
        | %empty                { $$ = NULL; }
        ;

maybe_anon_params : anon_params { $$ = $1; }
        | anon_params COMMA     { $$ = treealloc(MAYBE_ANON_PARAMS_R, "maybe_anon_params", 2, $1, $2); }
        | %empty                { $$ = NULL; }
        ;

anon_params : anon_param                 { $$ = $1; }
        | anon_params COMMA anon_param { $$ = treealloc(ANON_PARAMS_R, "anon_params", 3, $1, $2, $3); }
        ;

// anon means it's allowed to be anonymous (type-only), but it can
// still have a name
anon_param : named_arg COLON ty   { $$ = treealloc(ANON_PARAM_R, "anon_param", 3, $1, $2, $3); }
        | ty                     { $$ = $1; }
        ;

anon_params_allow_variadic_tail : COMMA TRIPLE_DOT          { $$ = treealloc(ANON_PARAMS_ALLOW_VARIADIC_TAIL_R, "anon_params_allow_variadic_tail", 2, $1, $2); }
        | COMMA anon_param anon_params_allow_variadic_tail { $$ = treealloc(ANON_PARAMS_ALLOW_VARIADIC_TAIL_R, "anon_params_allow_variadic_tail", 3, $1, $2, $3); }
        | %empty                                         { $$ = NULL; }
        ;

named_arg : ident                       { $$ = $1; }
        | UNDERSCORE                    { $$ = $1; }
        | AMPERSAND ident               { $$ = treealloc(NAMED_ARG_R, "named_arg", 2, $1, $2); }
        | AMPERSAND UNDERSCORE          { $$ = treealloc(NAMED_ARG_R, "named_arg", 2, $1, $2); }
        | DOUBLE_AMPERSAND ident        { $$ = treealloc(NAMED_ARG_R, "named_arg", 2, $1, $2); }
        | DOUBLE_AMPERSAND UNDERSCORE   { $$ = treealloc(NAMED_ARG_R, "named_arg", 2, $1, $2); }
        | MUT ident                     { $$ = treealloc(NAMED_ARG_R, "named_arg", 2, $1, $2); }
        ;

ret_ty : ARROW BANG         { $$ = treealloc(RET_TY_R, "ret_ty", 2, $1, $2); }
        | ARROW ty          { $$ = treealloc(RET_TY_R, "ret_ty", 2, $1, $2); }
        | %prec IDENTIFIER %empty { $$ = NULL; }
        ;

generic_params : LESS_THAN GREATER_THAN                                 { $$ = treealloc(GENERIC_PARAMS_R, "generic_params", 2, $1, $2); }
        | LESS_THAN lifetimes GREATER_THAN                              { $$ = treealloc(GENERIC_PARAMS_R, "generic_params", 3, $1, $2, $3); }
        | LESS_THAN lifetimes COMMA GREATER_THAN                        { $$ = treealloc(GENERIC_PARAMS_R, "generic_params", 4, $1, $2, $3, $4); }
        | LESS_THAN lifetimes DOUBLE_GREATER_THAN                       { $$ = treealloc(GENERIC_PARAMS_R, "generic_params", 3, $1, $2, $3); }
        | LESS_THAN lifetimes COMMA DOUBLE_GREATER_THAN                 { $$ = treealloc(GENERIC_PARAMS_R, "generic_params", 4, $1, $2, $3, $4); }
        | LESS_THAN lifetimes COMMA ty_params GREATER_THAN              { $$ = treealloc(GENERIC_PARAMS_R, "generic_params", 5, $1, $2, $3, $4, $5); }
        | LESS_THAN lifetimes COMMA ty_params COMMA GREATER_THAN        { $$ = treealloc(GENERIC_PARAMS_R, "generic_params", 6, $1, $2, $3, $4, $5, $6); }
        | LESS_THAN lifetimes COMMA ty_params DOUBLE_GREATER_THAN       { $$ = treealloc(GENERIC_PARAMS_R, "generic_params", 5, $1, $2, $3, $4, $5); }
        | LESS_THAN lifetimes COMMA ty_params COMMA DOUBLE_GREATER_THAN { $$ = treealloc(GENERIC_PARAMS_R, "generic_params", 6, $1, $2, $3, $4, $5, $6); }
        | LESS_THAN ty_params GREATER_THAN                              { $$ = treealloc(GENERIC_PARAMS_R, "generic_params", 3, $1, $2, $3); }
        | LESS_THAN ty_params COMMA GREATER_THAN                        { $$ = treealloc(GENERIC_PARAMS_R, "generic_params", 4, $1, $2, $3, $4); }
        | LESS_THAN ty_params DOUBLE_GREATER_THAN                       { $$ = treealloc(GENERIC_PARAMS_R, "generic_params", 3, $1, $2, $3); }
        | LESS_THAN ty_params COMMA DOUBLE_GREATER_THAN                 { $$ = treealloc(GENERIC_PARAMS_R, "generic_params", 4, $1, $2, $3, $4); }
        | %empty                                                        { $$ = NULL; }
        ;

maybe_where_clause : %empty                                             { $$ = NULL; }
        | where_clause                                                  { $$ = $1; }
        ;

where_clause : WHERE where_predicates   { $$ = treealloc(WHERE_CLAUSE_R, "where_clause", 2, $1, $2); }
        | WHERE where_predicates COMMA  { $$ = treealloc(WHERE_CLAUSE_R, "where_clause", 3, $1, $2, $3); }
        ;

where_predicates : where_predicate                      { $$ = $1; }
        | where_predicates COMMA where_predicate { $$ = treealloc(WHERE_PREDICATES_R, "where_predicates", 3, $1, $2, $3); }
        ;

where_predicate : maybe_for_lifetimes lifetime COLON bounds    { $$ = treealloc(WHERE_PREDICATE_R, "where_predicate", 4, $1, $2, $3, $4); }
        | maybe_for_lifetimes ty COLON ty_param_bounds { $$ = treealloc(WHERE_PREDICATE_R, "where_predicate", 4, $1, $2, $3, $4); }
        ;

maybe_for_lifetimes : FOR LESS_THAN lifetimes GREATER_THAN { $$ = treealloc(MAYBE_FOR_LIFETIMES_R, "maybe_for_lifetimes", 4, $1, $2, $3, $4); }
        | %prec FORTYPE %empty  {  }
        ;

ty_params : ty_param               { $$ = $1; }
        | ty_params COMMA ty_param { $$ = treealloc(TY_PARAMS_R, "ty_params", 3, $1, $2, $3); }
        ;

// A path with no type parameters; e.g. `foo::bar::Baz`
//
// These show up in 'use' view-items, because these are processed
// without respect to types.
path_no_types_allowed : ident                           { $$ = $1; }
        | DOUBLE_COLON ident                       { $$ = treealloc(PATH_NO_TYPES_ALLOWED_R, "path_no_types_allowed", 2, $1, $2); }
        | SELF                                { $$ = $1; }
        | DOUBLE_COLON SELF                        { $$ = treealloc(PATH_NO_TYPES_ALLOWED_R, "path_no_types_allowed", 2, $1, $2); }
        | SUPER                               { $$ = $1; }
        | DOUBLE_COLON SUPER                       { $$ = treealloc(PATH_NO_TYPES_ALLOWED_R, "path_no_types_allowed", 2, $1, $2); }
        | path_no_types_allowed DOUBLE_COLON ident { $$ = treealloc(PATH_NO_TYPES_ALLOWED_R, "path_no_types_allowed", 3, $1, $2, $3); }
        ;

// A path with a lifetime and type parameters, with no double colons
// before the type parameters; e.g. `foo::bar<'a>::Baz<T>`
//
// These show up in "trait references", the components of
// type-parameter bounds lists, as well as in the prefix of the
// path_generic_args_and_bounds rule, which is the full form of a
// named typed expression.
//
// They do not have (nor need) an extra '::' before '<' because
// unlike in expr context, there are no "less-than" type exprs to
// be ambiguous with.
path_generic_args_without_colons : %prec IDENTIFIER ident {
                $$ = $1;
          }
        | %prec IDENTIFIER  ident generic_args {
                $$ = treealloc(PATH_GENERIC_ARGS_WITHOUT_COLONS_R, "path_generic_args_without_colons", 2, $1, $2);}
        | %prec IDENTIFIER ident LEFT_PAREN maybe_ty_sums RIGHT_PAREN ret_ty {
                $$ = treealloc(PATH_GENERIC_ARGS_WITHOUT_COLONS_R, "path_generic_args_without_colons", 5, $1, $2, $3, $4, $5);
          }
        | %prec IDENTIFIER path_generic_args_without_colons DOUBLE_COLON ident {
                $$ = treealloc(PATH_GENERIC_ARGS_WITHOUT_COLONS_R, "path_generic_args_without_colons", 3, $1, $2, $3);
        }
        | %prec IDENTIFIER path_generic_args_without_colons DOUBLE_COLON ident
          generic_args                 { $$ = treealloc(PATH_GENERIC_ARGS_WITHOUT_COLONS_R, "path_generic_args_without_colons", 4, $1, $2, $3, $4); }
        | %prec IDENTIFIER path_generic_args_without_colons DOUBLE_COLON ident
          LEFT_PAREN maybe_ty_sums RIGHT_PAREN ret_ty { $$ = treealloc(PATH_GENERIC_ARGS_WITHOUT_COLONS_R, "path_generic_args_without_colons", 7, $1, $2, $3, $4, $5, $6, $7); }
        ;

generic_args : LESS_THAN generic_values GREATER_THAN   { $$ = treealloc(GENERIC_ARGS_R, "generic_args", 3, $1, $2, $3); }
        | LESS_THAN generic_values DOUBLE_GREATER_THAN   { $$ = treealloc(GENERIC_ARGS_R, "generic_args", 3, $1, $2, $3); }
        | LESS_THAN generic_values GREATER_THAN_EQUAL    { $$ = treealloc(GENERIC_ARGS_R, "generic_args", 3, $1, $2, $3); }
        | LESS_THAN generic_values DOUBLE_GREATER_THAN_EQUAL { $$ = treealloc(GENERIC_ARGS_R, "generic_args", 3, $1, $2, $3); }
// If generic_args starts with "<<", the first arg must be a
// TyQualifiedPath because that's the only type that can start with a
// '<'. This rule parses that as the first ty_sum and then continues
// with the rest of generic_values.
        | DOUBLE_LESS_THAN ty_qualified_path_and_generic_values GREATER_THAN   { $$ = treealloc(GENERIC_ARGS_R, "generic_args", 3, $1, $2, $3); }
        | DOUBLE_LESS_THAN ty_qualified_path_and_generic_values DOUBLE_GREATER_THAN   { $$ = treealloc(GENERIC_ARGS_R, "generic_args", 3, $1, $2, $3); }
        | DOUBLE_LESS_THAN ty_qualified_path_and_generic_values GREATER_THAN_EQUAL    { $$ = treealloc(GENERIC_ARGS_R, "generic_args", 3, $1, $2, $3); }
        | DOUBLE_LESS_THAN ty_qualified_path_and_generic_values DOUBLE_GREATER_THAN_EQUAL { $$ = treealloc(GENERIC_ARGS_R, "generic_args", 3, $1, $2, $3); }
        ;

generic_values : maybe_ty_sums_and_or_bindings { $$ = $1; }
        ;

maybe_ty_sums_and_or_bindings : ty_sums { $$ = $1; }
        | ty_sums COMMA { $$ = treealloc(MAYBE_TY_SUMS_AND_OR_BINDINGS_R, "maybe_ty_sums_and_or_bindings", 2, $1, $2); }
        | ty_sums COMMA bindings { $$ = treealloc(MAYBE_TY_SUMS_AND_OR_BINDINGS_R, "maybe_ty_sums_and_or_bindings", 3, $1, $2, $3); }
        | bindings { $$ = $1; }
        | bindings COMMA ty_sums { $$ = treealloc(MAYBE_TY_SUMS_AND_OR_BINDINGS_R, "maybe_ty_sums_and_or_bindings", 3, $1, $2, $3); }
        | %empty               { $$ = NULL; }
        ;

maybe_bindings : COMMA bindings { $$ = treealloc(MAYBE_BINDINGS_R, "maybe_bindings", 2, $1, $2); }
        | %empty       { $$ = NULL; }
        ;

////////////////////////////////////////////////////////////////////////
// Part 2: Patterns
////////////////////////////////////////////////////////////////////////

pat : UNDERSCORE                                      { $$ = $1; }
        | AMPERSAND pat                                         { $$ = treealloc(PAT_R, "pat", 2, $1, $2); }
        | AMPERSAND MUT pat                                     { $$ = treealloc(PAT_R, "pat", 3, $1, $2, $3); }
        | DOUBLE_AMPERSAND pat                                      { $$ = treealloc(PAT_R, "pat", 2, $1, $2); }
        | LEFT_PAREN RIGHT_PAREN                                         { $$ = treealloc(PAT_R, "pat", 2, $1, $2); }
        | LEFT_PAREN pat_tup RIGHT_PAREN                                 { $$ = treealloc(PAT_R, "pat", 3, $1, $2, $3); }
        | LEFT_BRACKET pat_vec RIGHT_BRACKET                                 { $$ = treealloc(PAT_R, "pat", 3, $1, $2, $3); }
        | lit_or_path { $$ = $1; }
        | lit_or_path TRIPLE_DOT lit_or_path               { $$ = treealloc(PAT_R, "pat", 3, $1, $2, $3); }
        | path_expr LEFT_BRACE pat_struct RIGHT_BRACE                    { $$ = treealloc(PAT_R, "pat", 4, $1, $2, $3, $4); }
        | path_expr LEFT_PAREN RIGHT_PAREN                               { $$ = treealloc(PAT_R, "pat", 3, $1, $2, $3); }
        | path_expr LEFT_PAREN pat_tup RIGHT_PAREN                       { $$ = treealloc(PAT_R, "pat", 4, $1, $2, $3, $4); }
        | path_expr BANG maybe_ident delimited_token_trees { $$ = treealloc(PAT_R, "pat", 4, $1, $2, $3, $4); }
        | binding_mode ident                              { $$ = treealloc(PAT_R, "pat", 2, $1, $2); }
        |              ident AT pat                      { $$ = treealloc(PAT_R, "pat", 3, $1, $2, $3); }
        | binding_mode ident AT pat                      { $$ = treealloc(PAT_R, "pat", 4, $1, $2, $3, $4); }
        | BOX pat                                         { $$ = treealloc(PAT_R, "pat", 2, $1, $2); }
        | LESS_THAN ty_sum maybe_as_trait_ref GREATER_THAN DOUBLE_COLON ident { $$ = treealloc(PAT_R, "pat", 6, $1, $2, $3, $4, $5, $6); }
        | DOUBLE_LESS_THAN ty_sum maybe_as_trait_ref GREATER_THAN DOUBLE_COLON ident
           maybe_as_trait_ref GREATER_THAN DOUBLE_COLON ident {
                $$ = treealloc(PAT_R, "pat", 10, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10);
          }
        ;

pats_or : pat              { $$ = $1; }
        | pats_or PIPE pat  { $$ = treealloc(PATS_OR_R, "pats_or", 3, $1, $2, $3); }
        ;

binding_mode : REF         { $$ = $1; }
        | REF MUT     { $$ = treealloc(BINDING_MODE_R, "binding_mode", 2, $1, $2); }
        | MUT         { $$ = $1; }
        ;

lit_or_path : path_expr    { $$ = $1; }
        | lit          { $$ = $1; }
        | MINUS lit      { $$ = treealloc(LIT_OR_PATH_R, "lit_or_path", 2, $1, $2); }
        ;

pat_field :                  ident        { $$ = $1; }
        |     binding_mode ident        { $$ = treealloc(PAT_FIELD_R, "pat_field", 2, $1, $2); }
        | BOX              ident        { $$ = treealloc(PAT_FIELD_R, "pat_field", 2, $1, $2); }
        | BOX binding_mode ident        { $$ = treealloc(PAT_FIELD_R, "pat_field", 3, $1, $2, $3); }
        |              ident COLON pat    { $$ = treealloc(PAT_FIELD_R, "pat_field", 3, $1, $2, $3); }
        | binding_mode ident COLON pat    { $$ = treealloc(PAT_FIELD_R, "pat_field", 4, $1, $2, $3, $4); }
        |        INTEGER_LITERAL COLON pat    { $$ = treealloc(PAT_FIELD_R, "pat_field", 3, $1, $2, $3); }
        ;

pat_fields : pat_field                  { $$ = $1; }
        | pat_fields COMMA pat_field   { $$ = treealloc(PAT_FIELDS_R, "pat_fields", 3, $1, $2, $3);}
        ;

pat_struct : pat_fields                 { $$ = $1; }
        | pat_fields COMMA             { $$ = treealloc(PAT_STRUCT_R, "pat_struct", 2, $1, $2); }
        | pat_fields COMMA DOUBLE_DOT      { $$ = treealloc(PAT_STRUCT_R, "pat_struct", 3, $1, $2, $3); }
        | DOUBLE_DOT                     { $$ = $1; }
        | %empty                     { $$ = NULL; }
        ;

pat_tup : pat_tup_elts                                  { $$ = $1; }
        | pat_tup_elts                             COMMA  { $$ = treealloc(PAT_TUP_R, "pat_tup", 2, $1, $2); }
        | pat_tup_elts     DOUBLE_DOT                       { $$ = treealloc(PAT_TUP_R, "pat_tup", 2, $1, $2); }
        | pat_tup_elts COMMA DOUBLE_DOT                       { $$ = treealloc(PAT_TUP_R, "pat_tup", 3, $1, $2, $3); }
        | pat_tup_elts     DOUBLE_DOT COMMA pat_tup_elts      { $$ = treealloc(PAT_TUP_R, "pat_tup", 4, $1, $2, $3, $4); }
        | pat_tup_elts     DOUBLE_DOT COMMA pat_tup_elts COMMA  { $$ = treealloc(PAT_TUP_R, "pat_tup", 5, $1, $2, $3, $4, $5); }
        | pat_tup_elts COMMA DOUBLE_DOT COMMA pat_tup_elts      { $$ = treealloc(PAT_TUP_R, "pat_tup", 5, $1, $2, $3, $4, $5); }
        | pat_tup_elts COMMA DOUBLE_DOT COMMA pat_tup_elts COMMA  { $$ = treealloc(PAT_TUP_R, "pat_tup", 6, $1, $2, $3, $4, $5, $6); }
        |                  DOUBLE_DOT COMMA pat_tup_elts      { $$ = treealloc(PAT_TUP_R, "pat_tup", 3, $1, $2, $3); }
        |                  DOUBLE_DOT COMMA pat_tup_elts COMMA  { $$ = treealloc(PAT_TUP_R, "pat_tup", 4, $1, $2, $3, $4); }
        |                  DOUBLE_DOT                       { $$ = $1; }
        ;

pat_tup_elts : pat                    { $$ = $1; }
        | pat_tup_elts COMMA pat        { $$ = treealloc(PAT_TUP_ELTS_R, "pat_tup_elts", 3, $1, $2, $3);}
        ;

pat_vec : pat_vec_elts                                  { $$ = $1;}
        | pat_vec_elts                             COMMA  { $$ = treealloc(PAT_VEC_R, "pat_vec", 2, $1, $2); }
        | pat_vec_elts     DOUBLE_DOT                       { $$ = treealloc(PAT_VEC_R, "pat_vec", 2, $1, $2); }
        | pat_vec_elts COMMA DOUBLE_DOT                       { $$ = treealloc(PAT_VEC_R, "pat_vec", 3, $1, $2, $3);}
        | pat_vec_elts     DOUBLE_DOT COMMA pat_vec_elts      { $$ = treealloc(PAT_VEC_R, "pat_vec", 4, $1, $2, $3, $4); }
        | pat_vec_elts     DOUBLE_DOT COMMA pat_vec_elts COMMA  { $$ = treealloc(PAT_VEC_R, "pat_vec", 5, $1, $2, $3, $4, $5); }
        | pat_vec_elts COMMA DOUBLE_DOT COMMA pat_vec_elts      { $$ = treealloc(PAT_VEC_R, "pat_vec", 5, $1, $2, $3, $4, $5); }
        | pat_vec_elts COMMA DOUBLE_DOT COMMA pat_vec_elts COMMA  { $$ = treealloc(PAT_VEC_R, "pat_vec", 6, $1, $2, $3, $4, $5, $6); }
        |                  DOUBLE_DOT COMMA pat_vec_elts      { $$ = treealloc(PAT_VEC_R, "pat_vec", 3, $1, $2, $3); }
        |                  DOUBLE_DOT COMMA pat_vec_elts COMMA  { $$ = treealloc(PAT_VEC_R, "pat_vec", 4, $1, $2, $3, $4);}
        |                  DOUBLE_DOT                       { $$ = $1; }
        | %empty                                        { $$ = NULL; }
        ;

pat_vec_elts : pat                    { $$ = $1; }
        | pat_vec_elts COMMA pat   { $$ = treealloc(PAT_VEC_ELTS_R, "pat_vec_elts", 3, $1, $2, $3); }
        ;

////////////////////////////////////////////////////////////////////////
// Part 3: Types
////////////////////////////////////////////////////////////////////////

ty : ty_prim { $$ = $1; }
        | ty_closure { $$ = $1; }
        | LESS_THAN ty_sum maybe_as_trait_ref GREATER_THAN DOUBLE_COLON ident { $$ = treealloc(TY_R, "ty", 6, $1, $2, $3, $4, $5, $6); }
        | DOUBLE_LESS_THAN ty_sum maybe_as_trait_ref GREATER_THAN DOUBLE_COLON ident
          maybe_as_trait_ref GREATER_THAN DOUBLE_COLON ident { $$ = treealloc(TY_R, "ty", 10, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10); }
        | LEFT_PAREN ty_sums RIGHT_PAREN                                 { $$ = treealloc(TY_R, "ty", 3, $1, $2, $3); }
        | LEFT_PAREN ty_sums COMMA RIGHT_PAREN                             { $$ = treealloc(TY_R, "ty", 4, $1, $2, $3, $4); }
        | LEFT_PAREN RIGHT_PAREN                                         { $$ = treealloc(TY_R, "ty", 2, $1, $2); }
        ;

ty_prim : %prec IDENTIFIER path_generic_args_without_colons    { $$ = $1; }
        | %prec IDENTIFIER DOUBLE_COLON path_generic_args_without_colons { $$ = treealloc(TY_PRIM_R, "ty_prim", 2, $1, $2); }
        | %prec IDENTIFIER SELF DOUBLE_COLON path_generic_args_without_colons { $$ = treealloc(TY_PRIM_R, "ty_prim", 3, $1, $2, $3); }
        | %prec IDENTIFIER path_generic_args_without_colons BANG maybe_ident
          delimited_token_trees         { $$ = treealloc(TY_PRIM_R, "ty_prim", 4, $1, $2, $3, $4); }
        | %prec IDENTIFIER DOUBLE_COLON path_generic_args_without_colons BANG
          maybe_ident delimited_token_trees { $$ = treealloc(TY_PRIM_R, "ty_prim", 5, $1, $2, $3, $4, $5); }
        | BOX ty                                                    { $$ = treealloc(TY_PRIM_R, "ty_prim", 2, $1, $2); }
        | STAR maybe_mut_or_const ty                                 { $$ = treealloc(TY_PRIM_R, "ty_prim", 3, $1, $2, $3); }
        | AMPERSAND ty                                                    { $$ = treealloc(TY_PRIM_R, "ty_prim", 2, $1, $2); }
        | AMPERSAND MUT ty                                                { $$ = treealloc(TY_PRIM_R, "ty_prim", 3, $1, $2, $3); }
        | DOUBLE_AMPERSAND ty                                                 { $$ = treealloc(TY_PRIM_R, "ty_prim", 2, $1, $2); }
        | DOUBLE_AMPERSAND MUT ty                                             { $$ = treealloc(TY_PRIM_R, "ty_prim", 3, $1, $2, $3); }
        | AMPERSAND lifetime maybe_mut ty                                 { $$ = treealloc(TY_PRIM_R, "ty_prim", 4, $1, $2, $3, $4); }
        | DOUBLE_AMPERSAND lifetime maybe_mut ty                              { $$ = treealloc(TY_PRIM_R, "ty_prim", 4, $1, $2, $3, $4); }
        | LEFT_BRACKET ty RIGHT_BRACKET                                                { $$ = treealloc(TY_PRIM_R, "ty_prim", 3, $1, $2, $3); }
        | LEFT_BRACKET ty COMMA DOUBLE_DOT expr RIGHT_BRACKET                                { $$ = treealloc(TY_PRIM_R, "ty_prim", 6, $1, $2, $3, $4, $5, $6); }
        | LEFT_BRACKET ty SEMICOLON expr RIGHT_BRACKET                                       { $$ = treealloc(TY_PRIM_R, "ty_prim", 5, $1, $2, $3, $4, $5); }
        | TYPEOF LEFT_PAREN expr RIGHT_PAREN                                       { $$ = treealloc(TY_PRIM_R, "ty_prim", 4, $1, $2, $3, $4); }
        | UNDERSCORE                                                { $$ = $1; }
        | ty_bare_fn                                               { $$ = $1; }
        | for_in_type                                             { $$ = $1; }
        ;

ty_bare_fn :                      FN ty_fn_decl { $$ = treealloc(TY_BARE_FN_R, "ty_bare_fn", 2, $1, $2); }
        | UNSAFE                  FN ty_fn_decl { $$ = treealloc(TY_BARE_FN_R, "ty_bare_fn", 3, $1, $2, $3); }
        |        EXTERN maybe_abi FN ty_fn_decl { $$ = treealloc(TY_BARE_FN_R, "ty_bare_fn", 4, $1, $2, $3, $4); }
        | UNSAFE EXTERN maybe_abi FN ty_fn_decl { $$ = treealloc(TY_BARE_FN_R, "ty_bare_fn", 5, $1, $2, $3, $4, $5); }
        ;

ty_fn_decl : generic_params fn_anon_params ret_ty { $$ = treealloc(TY_FN_DECL_R, "ty_fn_decl", 3, $1, $2, $3); }
        ;

ty_closure : UNSAFE PIPE anon_params PIPE maybe_bounds ret_ty { $$ = treealloc(TY_CLOSURE_R, "ty_closure", 6, $1, $2, $3, $4, $5, $6); }
        |           PIPE anon_params PIPE maybe_bounds ret_ty { $$ = treealloc(TY_CLOSURE_R, "ty_closure", 5, $1, $2, $3, $4, $5); }
        |    UNSAFE DOUBLE_PIPE maybe_bounds ret_ty                { $$ = treealloc(TY_CLOSURE_R, "ty_closure", 4, $1, $2, $3, $4); }
        |           DOUBLE_PIPE maybe_bounds ret_ty                { $$ = treealloc(TY_CLOSURE_R, "ty_closure", 3, $1, $2, $3); }
        ;

for_in_type : FOR LESS_THAN maybe_lifetimes GREATER_THAN for_in_type_suffix { $$ = treealloc(FOR_IN_TYPE_R, "for_in_type", 5, $1, $2, $3, $4, $5);}
        ;

for_in_type_suffix : ty_bare_fn { $$ = $1; }
        | trait_ref { $$ = $1; }
        | ty_closure { $$ = $1; }
        ;

maybe_mut : MUT              { $$ = $1; }
        | %prec MUT %empty { $$ = NULL; }
        ;

maybe_mut_or_const : MUT    { $$ = $1; }
        | CONST  { $$ = $1; }
        | %empty { $$ = NULL; }
        ;

ty_qualified_path_and_generic_values : ty_qualified_path maybe_bindings {
                $$ = treealloc(TY_QUALIFIED_PATH_AND_GENERIC_VALUES_R, "ty_qualified_path_and_generic_values", 2, $1, $2);
          }
        | ty_qualified_path COMMA ty_sums maybe_bindings {
                $$ = treealloc(TY_QUALIFIED_PATH_AND_GENERIC_VALUES_R, "ty_qualified_path_and_generic_values", 4, $1, $2, $3, $4);
          }
        ;

ty_qualified_path : ty_sum AS trait_ref GREATER_THAN DOUBLE_COLON ident           { $$ = treealloc(TY_QUALIFIED_PATH_R, "ty_qualified_path", 6, $1, $2, $3, $4, $5, $6); }
        | ty_sum AS trait_ref GREATER_THAN DOUBLE_COLON ident PLUS ty_param_bounds { $$ = treealloc(TY_QUALIFIED_PATH_R, "ty_qualified_path", 8, $1, $2, $3, $4, $5, $6, $7, $8); }
        ;

maybe_ty_sums : ty_sums { $$ = $1; }
        | ty_sums COMMA { $$ = treealloc(MAYBE_TY_SUMS_R, "maybe_ty_sums", 2, $1, $2); }
        | %empty { $$ = NULL; }
        ;

ty_sums : ty_sum             { $$ = $1;}
        | ty_sums COMMA ty_sum { $$ = treealloc(TY_SUMS_R, "ty_sums", 3, $1, $2, $3); }
        ;

ty_sum : ty_sum_elt            { $$ = $1; }
        | ty_sum PLUS ty_sum_elt { $$ = treealloc(TY_SUM_R, "ty_sum", 3, $1, $2, $3); }
        ;

ty_sum_elt : ty                  { $$ = $1; }
        | lifetime             { $$ = $1; }
        ;

ty_prim_sum : ty_prim_sum_elt                 { $$ = $1;}
        | ty_prim_sum PLUS ty_prim_sum_elt { $$ = treealloc(TY_PRIM_SUM_R, "ty_prim_sum", 3, $1, $2, $3);}
        ;

ty_prim_sum_elt : ty_prim { $$ = $1; }
        | lifetime { $$ = $1; }
        ;

maybe_ty_param_bounds : COLON ty_param_bounds { $$ = treealloc(MAYBE_TY_PARAM_BOUNDS_R, "maybe_ty_param_bounds", 2, $1, $2); }
        | %empty              { $$ = NULL; }
        ;

ty_param_bounds : boundseq { $$ = $1; }
        | %empty { $$ = NULL; }
        ;

boundseq : polybound { $$ = $1; }
        | boundseq PLUS polybound { $$ = treealloc(BOUNDSEQ_R, "boundseq", 3, $1, $2, $3); }
        ;

polybound : FOR LESS_THAN maybe_lifetimes GREATER_THAN bound { $$ = treealloc(POLYBOUND_R, "polybound", 5, $1, $2, $3, $4, $5); }
        | bound { $$ = $1; }
        | QUESTION FOR LESS_THAN maybe_lifetimes GREATER_THAN bound { $$ = treealloc(POLYBOUND_R, "polybound", 6, $1, $2, $3, $4, $5, $6); }
        | QUESTION bound { $$ = treealloc(POLYBOUND_R, "polybound", 2, $1, $2); }
        ;

bindings : binding              { $$ = $1; }
        | bindings COMMA binding { $$ = treealloc(BINDINGS_R, "bindings", 3, $1, $2, $3); }
        ;

binding : ident EQUAL ty { $$ = treealloc(BINDING_R, "binding", 3, $1, $2, $3); }
        ;

ty_param : ident maybe_ty_param_bounds maybe_ty_default           { $$ = treealloc(TY_PARAM_R, "ty_param", 3, $1, $2, $3); }
        | ident QUESTION ident maybe_ty_param_bounds maybe_ty_default { $$ = treealloc(TY_PARAM_R, "ty_param", 5, $1, $2, $3, $4, $5); }
        ;

maybe_bounds : %prec SHIFTPLUS COLON bounds             { $$ = treealloc(MAYBE_BOUNDS_R, "maybe_bounds", 2, $1, $2); }
        | %prec SHIFTPLUS %empty { $$ = NULL; }
        ;

bounds : bound            { $$ = $1;}
        | bounds PLUS bound { $$ = treealloc(BOUNDS_R, "bounds", 3, $1, $2, $3); }
        ;

bound : lifetime { $$ = $1; }
        | trait_ref { $$ = $1; }
        ;

maybe_ltbounds : %prec SHIFTPLUS COLON ltbounds       { $$ = treealloc(MAYBE_LTBOUNDS_R, "maybe_ltbounds", 2, $1, $2);}
        | %empty             { $$ = NULL; }
        ;

ltbounds : lifetime              { $$ = $1; }
        | ltbounds PLUS lifetime { $$ = treealloc(LTBOUNDS_R, "ltbounds", 3, $1, $2, $3); }
        ;

maybe_ty_default : EQUAL ty_sum { $$ = treealloc(MAYBE_TY_DEFAULT_R, "maybe_ty_default", 2, $1, $2); }
        | %empty     { $$ = NULL; }
        ;

maybe_lifetimes : lifetimes { $$ = $1; }
        | lifetimes COMMA { $$ = treealloc(MAYBE_LIFETIMES_R, "maybe_lifetimes", 2, $1, $2); }
        | %empty { $$ = NULL; }
        ;

lifetimes : lifetime_and_bounds               { $$ = $1; }
        | lifetimes COMMA lifetime_and_bounds { $$ = treealloc(LIFETIMES_R, "lifetimes", 3, $1, $2, $3); }
        ;

lifetime_and_bounds : LIFETIME maybe_ltbounds         { $$ = treealloc(LIFETIME_AND_BOUNDS_R, "lifetime_and_bounds", 2, $1, $2); }
        | STATIC_LIFETIME                 { $$ = $1; }
        ;

lifetime : LIFETIME         { $$ = $1; }
        | STATIC_LIFETIME  { $$ = $1; }
        ;

trait_ref : %prec IDENTIFIER path_generic_args_without_colons { $$ = $1; }
        | %prec IDENTIFIER DOUBLE_COLON path_generic_args_without_colons { $$ = treealloc(TRAIT_REF_R, "trait_ref", 2, $1, $2); }
        ;

////////////////////////////////////////////////////////////////////////
// Part 4: Blocks, statements, and expressions
////////////////////////////////////////////////////////////////////////

inner_attrs_and_block : LEFT_BRACE maybe_inner_attrs maybe_stmts RIGHT_BRACE        { $$ = treealloc(INNER_ATTRS_AND_BLOCK_R, "inner_attrs_and_block", 4, $1, $2, $3, $4); }
        ;

block : LEFT_BRACE maybe_stmts RIGHT_BRACE                          { $$ = treealloc(BLOCK_R, "block", 3, $1, $2, $3); }
        ;

maybe_stmts : stmts { $$ = $1; }
        | stmts nonblock_expr { $$ = treealloc(MAYBE_STMTS_R, "maybe_stmts", 2, $1, $2); }
        | nonblock_expr { $$ = $1; }
        | %empty              { $$ = NULL; }
        ;

// There are two sub-grammars within a "stmts: exprs" derivation
// depending on whether each stmt-expr is a block-expr form; this is to
// handle the "semicolon rule" for stmt sequencing that permits
// writing
//
//     if foo { bar } 10
//
// as a sequence of two stmts (one if-expr stmt, one lit-10-expr
// stmt). Unfortunately by permitting juxtaposition of exprs in
// sequence like that, the non-block expr grammar has to have a
// second limited sub-grammar that excludes the prefix exprs that
// are ambiguous with binops. That is to say:
//
//     {10} - 1
//
// should parse as (progn (progn 10) (- 1)) not (- (progn 10) 1), that
// is to say, two statements rather than one, at least according to
// the mainline rust parser.
//
// So we wind up with a 3-way split in exprs that occur in stmt lists:
// block, nonblock-prefix, and nonblock-nonprefix.
//
// In non-stmts contexts, expr can relax this trichotomy.

stmts : stmt           { $$ = $1; }
        | stmts stmt     { $$ = treealloc(STMTS_R, "stmts", 2, $1, $2); }
        ;

stmt : maybe_outer_attrs let                    { $$ = treealloc(STMT_R, "stmt", 2, $1, $2); }
        |                 stmt_item             { $$ = $1; }
        |             PUB stmt_item             { $$ = treealloc(STMT_R, "stmt", 2, $1, $2); }
        | outer_attrs     stmt_item             { $$ = treealloc(STMT_R, "stmt", 2, $1, $2); }
        | outer_attrs PUB stmt_item             { $$ = treealloc(STMT_R, "stmt", 3, $1, $2, $3); }
        | full_block_expr                       { $$ = $1; }
        | maybe_outer_attrs block               { $$ = treealloc(STMT_R, "stmt", 2, $1, $2); }
        |             nonblock_expr SEMICOLON   { $$ = treealloc(STMT_R, "stmt", 2, $1, $2); }
        | outer_attrs nonblock_expr SEMICOLON   { $$ = treealloc(STMT_R, "stmt", 3, $1, $2, $3); }
        | SEMICOLON                             { $$ = $1; }
        ;

maybe_exprs : exprs                             { $$ = $1; }
        | exprs COMMA                           { $$ = treealloc(MAYBE_EXPRS_R, "maybe_exprs", 2, $1, $2); }
        | %empty                                { $$ = NULL; }
        ;

maybe_expr : expr                                                       { $$ = $1; }
        | %empty                                                        { $$ = NULL; }
        ;

exprs : expr                                                            { $$ = $1; }
        | exprs COMMA expr                                              { $$ = treealloc(EXPRS_R, "exprs", 3, $1, $2, $3); }
        ;

path_expr : path_generic_args_with_colons                               { $$ = $1; }
        | DOUBLE_COLON path_generic_args_with_colons                    { $$ = treealloc(PATH_EXPR_R, "path_expr", 2, $1, $2); }
        | SELF DOUBLE_COLON path_generic_args_with_colons               { $$ = treealloc(PATH_EXPR_R, "path_expr", 3, $1, $2, $3); }
        ;

// A path with a lifetime and type parameters with double colons before
// the type parameters; e.g. `foo::bar::<'a>::Baz::<T>`
//
// These show up in expr context, in order to disambiguate from "less-than"
// expressions.
path_generic_args_with_colons : ident                                   { $$ = $1; }
        | SUPER                                                         { $$ = $1; }
        | path_generic_args_with_colons DOUBLE_COLON ident              { $$ = treealloc(PATH_GENERIC_ARGS_WITH_COLONS_R, "path_generic_args_with_colons", 3, $1, $2, $3); }
        | path_generic_args_with_colons DOUBLE_COLON SUPER              { $$ = treealloc(PATH_GENERIC_ARGS_WITH_COLONS_R, "path_generic_args_with_colons", 3, $1, $2, $3); }
        | path_generic_args_with_colons DOUBLE_COLON generic_args       { $$ = treealloc(PATH_GENERIC_ARGS_WITH_COLONS_R, "path_generic_args_with_colons", 3, $1, $2, $3); }
        ;

// the braces-delimited macro is a block_expr so it doesn't appear here
macro_expr : path_expr BANG maybe_ident parens_delimited_token_trees    { $$ = treealloc(MACRO_EXPR_R, "macro_expr", 4, $1, $2, $3, $4); }
        | path_expr BANG maybe_ident brackets_delimited_token_trees     { $$ = treealloc(MACRO_EXPR_R, "macro_expr", 4, $1, $2, $3, $4); }
        ;

nonblock_expr : lit                                                     { $$ = $1; }
        | %prec IDENTIFIER path_expr                                    { $$ = $1; }
        | SELF                                                          { $$ = $1; }
        | macro_expr                                                    { $$ = $1; }
        | path_expr LEFT_BRACE struct_expr_fields RIGHT_BRACE           { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 4, $1, $2, $3, $4); }
        | nonblock_expr QUESTION                                        { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 2, $1, $2); }
        | nonblock_expr DOT path_generic_args_with_colons               { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 3, $1, $2, $3); }
        | nonblock_expr DOT INTEGER_LITERAL                             { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 3, $1, $2, $3); }
        | nonblock_expr LEFT_BRACKET maybe_expr RIGHT_BRACKET           { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 4, $1, $2, $3, $4); }
        | nonblock_expr LEFT_PAREN maybe_exprs RIGHT_PAREN              { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 4, $1, $2, $3, $4); }
        | LEFT_BRACKET vec_expr RIGHT_BRACKET                           { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 3, $1, $2, $3); }
        | LEFT_PAREN maybe_exprs RIGHT_PAREN                            { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 3, $1, $2, $3); }
        | CONTINUE                                                      { $$ = $1; }
        | CONTINUE lifetime                                             { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 2, $1, $2); }
        | RETURN                                                        { $$ = $1; }
        | RETURN expr                                                   { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 2, $1, $2); }
        | BREAK                                                         { $$ = $1; }
        | BREAK lifetime                                                { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 2, $1, $2); }
        | YIELD                                                         { $$ = $1; }
        | YIELD expr                                                    { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 2, $1, $2); }
        | nonblock_expr EQUAL expr                                      { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 3, $1, $2, $3); }
        | nonblock_expr DOUBLE_LESS_THAN_EQUAL expr                     { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 3, $1, $2, $3); }
        | nonblock_expr DOUBLE_GREATER_THAN_EQUAL expr                  { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 3, $1, $2, $3); }
        | nonblock_expr MINUS_EQUAL expr                                { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 3, $1, $2, $3); }
        | nonblock_expr AMPERSAND_EQUAL expr                            { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 3, $1, $2, $3); }
        | nonblock_expr PIPE_EQUAL expr                                 { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 3, $1, $2, $3); }
        | nonblock_expr PLUS_EQUAL expr                                 { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 3, $1, $2, $3); }
        | nonblock_expr STAR_EQUAL expr                                 { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 3, $1, $2, $3); }
        | nonblock_expr SLASH_EQUAL expr                                { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 3, $1, $2, $3); }
        | nonblock_expr CARET_EQUAL expr                                { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 3, $1, $2, $3); }
        | nonblock_expr PERCENT_EQUAL expr                              { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 3, $1, $2, $3); }
        | nonblock_expr DOUBLE_PIPE expr                                { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 3, $1, $2, $3); }
        | nonblock_expr DOUBLE_AMPERSAND expr                           { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 3, $1, $2, $3); }
        | nonblock_expr DOUBLE_EQUAL expr                               { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 3, $1, $2, $3); }
        | nonblock_expr NOT_EQUAL expr                                  { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 3, $1, $2, $3); }
        | nonblock_expr LESS_THAN expr                                  { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 3, $1, $2, $3); }
        | nonblock_expr GREATER_THAN expr                               { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 3, $1, $2, $3); }
        | nonblock_expr LESS_THAN_EQUAL expr                            { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 3, $1, $2, $3); }
        | nonblock_expr GREATER_THAN_EQUAL expr                         { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 3, $1, $2, $3); }
        | nonblock_expr PIPE expr                                       { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 3, $1, $2, $3); }
        | nonblock_expr CARET expr                                      { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 3, $1, $2, $3); }
        | nonblock_expr AMPERSAND expr                                  { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 3, $1, $2, $3); }
        | nonblock_expr DOUBLE_LESS_THAN expr                           { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 3, $1, $2, $3); }
        | nonblock_expr DOUBLE_GREATER_THAN expr                        { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 3, $1, $2, $3); }
        | nonblock_expr PLUS expr                                       { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 3, $1, $2, $3); }
        | nonblock_expr MINUS expr                                      { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 3, $1, $2, $3); }
        | nonblock_expr STAR expr                                       { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 3, $1, $2, $3); }
        | nonblock_expr SLASH expr                                      { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 3, $1, $2, $3); }
        | nonblock_expr PERCENT expr                                    { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 3, $1, $2, $3); }
        | nonblock_expr DOUBLE_DOT                                      { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 2, $1, $2); }
        | nonblock_expr DOUBLE_DOT expr                                 { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 3, $1, $2, $3); }
        |               DOUBLE_DOT expr                                 { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 2, $1, $2); }
        |               DOUBLE_DOT                                      { $$ = $1; }
        | nonblock_expr AS ty                                           { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 3, $1, $2, $3); }
        | nonblock_expr COLON ty                                        { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 3, $1, $2, $3); }
        | BOX expr                                                      { $$ = treealloc(NONBLOCK_EXPR_R, "nonblock_expr", 2, $1, $2); }
        | expr_qualified_path                                           { $$ = $1; }
        | nonblock_prefix_expr                                          { $$ = $1; }
        ;

expr : lit                                                              { $$ = $1; }
     | %prec IDENTIFIER path_expr                                       { $$ = $1; }
     | SELF                                                             { $$ = $1; }
     | macro_expr                                                       { $$ = $1; }
     | path_expr LEFT_BRACE struct_expr_fields RIGHT_BRACE              { $$ = treealloc(EXPR_R, "expr", 4, $1, $2, $3, $4);}
     | expr QUESTION                                                    { $$ = treealloc(EXPR_R, "expr", 2, $1, $2); }
     | expr DOT path_generic_args_with_colons                           { $$ = treealloc(EXPR_R, "expr", 3, $1, $2, $3);}
     | expr DOT INTEGER_LITERAL                                         { $$ = treealloc(EXPR_R, "expr", 3, $1, $2, $3);}
     | expr LEFT_BRACKET maybe_expr RIGHT_BRACKET                       { $$ = treealloc(EXPR_R, "expr", 4, $1, $2, $3, $4); }
     | expr LEFT_PAREN maybe_exprs RIGHT_PAREN                          { $$ = treealloc(EXPR_R, "expr", 4, $1, $2, $3, $4); }
     | LEFT_PAREN maybe_exprs RIGHT_PAREN                               { $$ = treealloc(EXPR_R, "expr", 3, $1, $2, $3); }
     | LEFT_BRACKET vec_expr RIGHT_BRACKET                              { $$ = treealloc(EXPR_R, "expr", 3, $1, $2, $3); }
     | CONTINUE                                                         { $$ = $1; }
     | CONTINUE ident                                                   { $$ = treealloc(EXPR_R, "expr", 2, $1, $2); }
     | RETURN                                                           { $$ = $1; }
     | RETURN expr                                                      { $$ = treealloc(EXPR_R, "expr", 2, $1, $2); }
     | BREAK                                                            { $$ = $1; }
     | BREAK ident                                                      { $$ = treealloc(EXPR_R, "expr", 2, $1, $2);}
     | YIELD                                                            { $$ = $1; }
     | YIELD expr                                                       { $$ = treealloc(EXPR_R, "expr", 2, $1, $2); }
     | expr EQUAL expr                                                  { $$ = treealloc(EXPR_R, "expr", 3, $1, $2, $3); }
     | expr DOUBLE_LESS_THAN_EQUAL expr                                 { $$ = treealloc(EXPR_R, "expr", 3, $1, $2, $3); }
     | expr DOUBLE_GREATER_THAN_EQUAL expr                              { $$ = treealloc(EXPR_R, "expr", 3, $1, $2, $3); }
     | expr MINUS_EQUAL expr                                            { $$ = treealloc(EXPR_R, "expr", 3, $1, $2, $3); }
     | expr AMPERSAND_EQUAL expr                                        { $$ = treealloc(EXPR_R, "expr", 3, $1, $2, $3); }
     | expr PIPE_EQUAL expr                                             { $$ = treealloc(EXPR_R, "expr", 3, $1, $2, $3); }
     | expr PLUS_EQUAL expr                                             { $$ = treealloc(EXPR_R, "expr", 3, $1, $2, $3); }
     | expr STAR_EQUAL expr                                             { $$ = treealloc(EXPR_R, "expr", 3, $1, $2, $3); }
     | expr SLASH_EQUAL expr                                            { $$ = treealloc(EXPR_R, "expr", 3, $1, $2, $3); }
     | expr CARET_EQUAL expr                                            { $$ = treealloc(EXPR_R, "expr", 3, $1, $2, $3); }
     | expr PERCENT_EQUAL expr                                          { $$ = treealloc(EXPR_R, "expr", 3, $1, $2, $3); }
     | expr DOUBLE_PIPE expr                                            { $$ = treealloc(EXPR_R, "expr", 3, $1, $2, $3); }
     | expr DOUBLE_AMPERSAND expr                                       { $$ = treealloc(EXPR_R, "expr", 3, $1, $2, $3); }
     | expr DOUBLE_EQUAL expr                                           { $$ = treealloc(EXPR_R, "expr", 3, $1, $2, $3); }
     | expr NOT_EQUAL expr                                              { $$ = treealloc(EXPR_R, "expr", 3, $1, $2, $3); }
     | expr LESS_THAN expr                                              { $$ = treealloc(EXPR_R, "expr", 3, $1, $2, $3); }
     | expr GREATER_THAN expr                                           { $$ = treealloc(EXPR_R, "expr", 3, $1, $2, $3); }
     | expr LESS_THAN_EQUAL expr                                        { $$ = treealloc(EXPR_R, "expr", 3, $1, $2, $3); }
     | expr GREATER_THAN_EQUAL expr                                     { $$ = treealloc(EXPR_R, "expr", 3, $1, $2, $3); }
     | expr PIPE expr                                                   { $$ = treealloc(EXPR_R, "expr", 3, $1, $2, $3); }
     | expr CARET expr                                                  { $$ = treealloc(EXPR_R, "expr", 3, $1, $2, $3); }
     | expr AMPERSAND expr                                              { $$ = treealloc(EXPR_R, "expr", 3, $1, $2, $3); }
     | expr DOUBLE_LESS_THAN expr                                       { $$ = treealloc(EXPR_R, "expr", 3, $1, $2, $3); }
     | expr DOUBLE_GREATER_THAN expr                                    { $$ = treealloc(EXPR_R, "expr", 3, $1, $2, $3); }
     | expr PLUS expr                                                   { $$ = treealloc(EXPR_R, "expr", 3, $1, $2, $3); }
     | expr MINUS expr                                                  { $$ = treealloc(EXPR_R, "expr", 3, $1, $2, $3); }
     | expr STAR expr                                                   { $$ = treealloc(EXPR_R, "expr", 3, $1, $2, $3); }
     | expr SLASH expr                                                  { $$ = treealloc(EXPR_R, "expr", 3, $1, $2, $3); }
     | expr PERCENT expr                                                { $$ = treealloc(EXPR_R, "expr", 3, $1, $2, $3); }
     | expr DOUBLE_DOT                                                  { $$ = treealloc(EXPR_R, "expr", 2, $1, $2); }
     | expr DOUBLE_DOT expr                                             { $$ = treealloc(EXPR_R, "expr", 3, $1, $2, $3); }
     |      DOUBLE_DOT expr                                             { $$ = treealloc(EXPR_R, "expr", 2, $1, $2); }
     |      DOUBLE_DOT                                                  { $$ = $1; }
     | expr AS ty                                                       { $$ = treealloc(EXPR_R, "expr", 3, $1, $2, $3); }
     | expr COLON ty                                                    { $$ = treealloc(EXPR_R, "expr", 3, $1, $2, $3); }
     | BOX expr                                                         { $$ = treealloc(EXPR_R, "expr", 2, $1, $2); }
     | expr_qualified_path                                              { $$ = $1; }
     | block_expr                                                       { $$ = $1; }
     | block                                                            { $$ = $1; }
     | nonblock_prefix_expr                                             { $$ = $1; }
     ;

expr_nostruct : lit                                                     { $$ = $1; }
        | %prec IDENTIFIER path_expr                                    { $$ = $1; }
        | SELF                                                          { $$ = $1; }
        | macro_expr                                                    { $$ = $1; }
        | expr_nostruct QUESTION                                        { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 2, $1, $2); }
        | expr_nostruct DOT path_generic_args_with_colons               { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 3, $1, $2, $3); }
        | expr_nostruct DOT INTEGER_LITERAL                             { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 3, $1, $2, $3); }
        | expr_nostruct LEFT_BRACKET maybe_expr RIGHT_BRACKET           { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 4, $1, $2, $3, $4); }
        | expr_nostruct LEFT_PAREN maybe_exprs RIGHT_PAREN              { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 4, $1, $2, $3, $4); }
        | LEFT_BRACKET vec_expr RIGHT_BRACKET                           { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 3, $1, $2, $3); }
        | LEFT_PAREN maybe_exprs RIGHT_PAREN                            { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 3, $1, $2, $3); }
        | CONTINUE                                                      { $$ = $1; }
        | CONTINUE ident                                                { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 2, $1, $2); }
        | RETURN                                                        { $$ = $1; }
        | RETURN expr                                                   { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 2, $1, $2); }
        | BREAK                                                         { $$ = $1; }
        | BREAK ident                                                   { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 2, $1, $2); }
        | YIELD                                                         { $$ = $1; }
        | YIELD expr                                                    { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 2, $1, $2); }
        | expr_nostruct EQUAL expr_nostruct                             { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 3, $1, $2, $3); }
        | expr_nostruct DOUBLE_LESS_THAN_EQUAL expr_nostruct            { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 3, $1, $2, $3); }
        | expr_nostruct DOUBLE_GREATER_THAN_EQUAL expr_nostruct         { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 3, $1, $2, $3); }
        | expr_nostruct MINUS_EQUAL expr_nostruct                       { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 3, $1, $2, $3); }
        | expr_nostruct AMPERSAND_EQUAL expr_nostruct                   { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 3, $1, $2, $3); }
        | expr_nostruct PIPE_EQUAL expr_nostruct                        { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 3, $1, $2, $3); }
        | expr_nostruct PLUS_EQUAL expr_nostruct                        { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 3, $1, $2, $3); }
        | expr_nostruct STAR_EQUAL expr_nostruct                        { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 3, $1, $2, $3); }
        | expr_nostruct SLASH_EQUAL expr_nostruct                       { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 3, $1, $2, $3); }
        | expr_nostruct CARET_EQUAL expr_nostruct                       { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 3, $1, $2, $3); }
        | expr_nostruct PERCENT_EQUAL expr_nostruct                     { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 3, $1, $2, $3); }
        | expr_nostruct DOUBLE_PIPE expr_nostruct                       { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 3, $1, $2, $3); }
        | expr_nostruct DOUBLE_AMPERSAND expr_nostruct                  { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 3, $1, $2, $3); }
        | expr_nostruct DOUBLE_EQUAL expr_nostruct                      { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 3, $1, $2, $3); }
        | expr_nostruct NOT_EQUAL expr_nostruct                         { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 3, $1, $2, $3); }
        | expr_nostruct LESS_THAN expr_nostruct                         { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 3, $1, $2, $3); }
        | expr_nostruct GREATER_THAN expr_nostruct                      { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 3, $1, $2, $3); }
        | expr_nostruct LESS_THAN_EQUAL expr_nostruct                   { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 3, $1, $2, $3); }
        | expr_nostruct GREATER_THAN_EQUAL expr_nostruct                { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 3, $1, $2, $3); }
        | expr_nostruct PIPE expr_nostruct                              { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 3, $1, $2, $3); }
        | expr_nostruct CARET expr_nostruct                             { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 3, $1, $2, $3); }
        | expr_nostruct AMPERSAND expr_nostruct                         { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 3, $1, $2, $3); }
        | expr_nostruct DOUBLE_LESS_THAN expr_nostruct                  { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 3, $1, $2, $3); }
        | expr_nostruct DOUBLE_GREATER_THAN expr_nostruct               { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 3, $1, $2, $3); }
        | expr_nostruct PLUS expr_nostruct                              { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 3, $1, $2, $3); }
        | expr_nostruct MINUS expr_nostruct                             { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 3, $1, $2, $3); }
        | expr_nostruct STAR expr_nostruct                              { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 3, $1, $2, $3); }
        | expr_nostruct SLASH expr_nostruct                             { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 3, $1, $2, $3); }
        | expr_nostruct PERCENT expr_nostruct                           { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 3, $1, $2, $3); }
        | expr_nostruct DOUBLE_DOT               %prec RANGE            { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 2, $1, $2); }
        | expr_nostruct DOUBLE_DOT expr_nostruct                        { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 3, $1, $2, $3); }
        |               DOUBLE_DOT expr_nostruct                        { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 2, $1, $2); }
        |               DOUBLE_DOT                                      { $$ = $1; }
        | expr_nostruct AS ty                                           { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 3, $1, $2, $3); }
        | expr_nostruct COLON ty                                        { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 3, $1, $2, $3); }
        | BOX expr                                                      { $$ = treealloc(EXPR_NOSTRUCT_R, "expr_nostruct", 2, $1, $2); }
        | expr_qualified_path                                           { $$ = $1; }
        | block_expr                                                    { $$ = $1; }
        | block                                                         { $$ = $1; }
        | nonblock_prefix_expr_nostruct                                 { $$ = $1; }
        ;

nonblock_prefix_expr_nostruct : MINUS expr_nostruct                     { $$ = treealloc(NONBLOCK_PREFIX_EXPR_NOSTRUCT_R, "nonblock_prefix_expr_nostruct", 2, $1, $2); }
        | BANG expr_nostruct                                            { $$ = treealloc(NONBLOCK_PREFIX_EXPR_NOSTRUCT_R, "nonblock_prefix_expr_nostruct", 2, $1, $2); }
        | STAR expr_nostruct                                            { $$ = treealloc(NONBLOCK_PREFIX_EXPR_NOSTRUCT_R, "nonblock_prefix_expr_nostruct", 2, $1, $2); }
        | AMPERSAND maybe_mut expr_nostruct                             { $$ = treealloc(NONBLOCK_PREFIX_EXPR_NOSTRUCT_R, "nonblock_prefix_expr_nostruct", 3, $1, $2, $3); }
        | DOUBLE_AMPERSAND maybe_mut expr_nostruct                      { $$ = treealloc(NONBLOCK_PREFIX_EXPR_NOSTRUCT_R, "nonblock_prefix_expr_nostruct", 3, $1, $2, $3); }
        | lambda_expr_nostruct                                          { $$ = $1; }
        | MOVE lambda_expr_nostruct                                     { $$ = treealloc(NONBLOCK_PREFIX_EXPR_NOSTRUCT_R, "nonblock_prefix_expr_nostruct", 2, $1, $2); }
        ;

nonblock_prefix_expr : MINUS expr                                       { $$ = treealloc(NONBLOCK_PREFIX_EXPR_R, "nonblock_prefix_expr", 2, $1, $2);}
        | BANG expr                                                     { $$ = treealloc(NONBLOCK_PREFIX_EXPR_R, "nonblock_prefix_expr", 2, $1, $2); }
        | STAR expr                                                     { $$ = treealloc(NONBLOCK_PREFIX_EXPR_R, "nonblock_prefix_expr", 2, $1, $2); }
        | AMPERSAND maybe_mut expr                                      { $$ = treealloc(NONBLOCK_PREFIX_EXPR_R, "nonblock_prefix_expr", 3, $1, $2, $3); }
        | DOUBLE_AMPERSAND maybe_mut expr                               { $$ = treealloc(NONBLOCK_PREFIX_EXPR_R, "nonblock_prefix_expr", 3, $1, $2, $3); }
        | lambda_expr                                                   { $$ = $1; }
        | MOVE lambda_expr                                              { $$ = treealloc(NONBLOCK_PREFIX_EXPR_R, "nonblock_prefix_expr", 2, $1, $2); }
        ;

expr_qualified_path : LESS_THAN ty_sum maybe_as_trait_ref GREATER_THAN DOUBLE_COLON ident
        	       maybe_qpath_params {
                $$ = treealloc(EXPR_QUALIFIED_PATH_R, "expr_qualified_path", 7, $1, $2, $3, $4, $5, $6, $7);
          }
        | DOUBLE_LESS_THAN ty_sum maybe_as_trait_ref GREATER_THAN DOUBLE_COLON ident
          maybe_as_trait_ref GREATER_THAN DOUBLE_COLON ident {
                $$ = treealloc(EXPR_QUALIFIED_PATH_R, "expr_qualified_path", 10, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10);
          }
        | DOUBLE_LESS_THAN ty_sum maybe_as_trait_ref GREATER_THAN DOUBLE_COLON ident
          generic_args maybe_as_trait_ref GREATER_THAN DOUBLE_COLON ident {
                $$ = treealloc(EXPR_QUALIFIED_PATH_R, "expr_qualified_path", 11, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11);
          }
        | DOUBLE_LESS_THAN ty_sum maybe_as_trait_ref GREATER_THAN DOUBLE_COLON ident
          maybe_as_trait_ref GREATER_THAN DOUBLE_COLON ident generic_args {
                $$ = treealloc(EXPR_QUALIFIED_PATH_R, "expr_qualified_path", 11, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11);
          }
        | DOUBLE_LESS_THAN ty_sum maybe_as_trait_ref GREATER_THAN DOUBLE_COLON ident
          generic_args maybe_as_trait_ref GREATER_THAN DOUBLE_COLON ident generic_args {
                $$ = treealloc(EXPR_QUALIFIED_PATH_R, "expr_qualified_path", 12, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12);
          }
        ;

maybe_qpath_params : DOUBLE_COLON generic_args { $$ = treealloc(MAYBE_QPATH_PARAMS_R, "maybe_qpath_params", 2, $1, $2); }
        | %empty               { $$ = NULL; }
        ;

maybe_as_trait_ref : AS trait_ref { $$ = treealloc(MAYBE_AS_TRAIT_REF_R, "maybe_as_trait_ref", 2, $1, $2); }
        | %empty       { $$ = NULL; }
        ;

lambda_expr : %prec LAMBDA DOUBLE_PIPE ret_ty expr                          { $$ = treealloc(LAMBDA_EXPR_R, "lambda_expr", 3, $1, $2, $3); }
        | %prec LAMBDA PIPE PIPE ret_ty expr                           { $$ = treealloc(LAMBDA_EXPR_R, "lambda_expr", 4, $1, $2, $3, $4); }
        | %prec LAMBDA PIPE inferrable_params PIPE ret_ty expr         { $$ = treealloc(LAMBDA_EXPR_R, "lambda_expr", 5, $1, $2, $3, $4, $5); }
        | %prec LAMBDA PIPE inferrable_params DOUBLE_PIPE lambda_expr_no_first_bar { $$ = treealloc(LAMBDA_EXPR_R, "lambda_expr", 4, $1, $2, $3, $4); }
        ;

lambda_expr_no_first_bar : %prec LAMBDA PIPE ret_ty expr                { $$ = treealloc(LAMBDA_EXPR_NO_FIRST_BAR_R, "lambda_expr_no_first_bar", 3, $1, $2, $3); }
        | %prec LAMBDA inferrable_params PIPE ret_ty expr               { $$ = treealloc(LAMBDA_EXPR_NO_FIRST_BAR_R, "lambda_expr_no_first_bar", 4, $1, $2, $3, $4); }
        | %prec LAMBDA inferrable_params DOUBLE_PIPE lambda_expr_no_first_bar { $$ = treealloc(LAMBDA_EXPR_NO_FIRST_BAR_R, "lambda_expr_no_first_bar", 3, $1, $2, $3); }
        ;

lambda_expr_nostruct : %prec LAMBDA DOUBLE_PIPE expr_nostruct                 { $$ = treealloc(LAMBDA_EXPR_NOSTRUCT_R, "lambda_expr_nostruct", 2, $1, $2); }
        | %prec LAMBDA PIPE PIPE ret_ty expr_nostruct                    { $$ = treealloc(LAMBDA_EXPR_NOSTRUCT_R, "lambda_expr_nostruct", 4, $1, $2, $3, $4); }
        | %prec LAMBDA PIPE inferrable_params PIPE expr_nostruct         { $$ = treealloc(LAMBDA_EXPR_NOSTRUCT_R, "lambda_expr_nostruct", 4, $1, $2, $3, $4); }
        | %prec LAMBDA PIPE inferrable_params DOUBLE_PIPE
          lambda_expr_nostruct_no_first_bar { $$ = treealloc(LAMBDA_EXPR_NOSTRUCT_R, "lambda_expr_nostruct", 4, $1, $2, $3, $4); }
        ;

lambda_expr_nostruct_no_first_bar : %prec LAMBDA PIPE ret_ty expr_nostruct { $$ = treealloc(LAMBDA_EXPR_NOSTRUCT_NO_FIRST_BAR_R, "lambda_expr_nostruct_no_first_bar", 3, $1, $2, $3); }
        | %prec LAMBDA inferrable_params PIPE ret_ty expr_nostruct         { $$ = treealloc(LAMBDA_EXPR_NOSTRUCT_NO_FIRST_BAR_R, "lambda_expr_nostruct_no_first_bar", 4, $1, $2, $3, $4); }
        | %prec LAMBDA inferrable_params DOUBLE_PIPE
          lambda_expr_nostruct_no_first_bar { $$ = treealloc(LAMBDA_EXPR_NOSTRUCT_NO_FIRST_BAR_R, "lambda_expr_nostruct_no_first_bar", 3, $1, $2, $3); }
        ;

vec_expr : maybe_exprs { $$ = $1; }
        | exprs SEMICOLON expr { $$ = treealloc(VEC_EXPR_R, "vec_expr", 3, $1, $2, $3); }
        ;

struct_expr_fields : field_inits { $$ = $1; }
        | field_inits COMMA { $$ = treealloc(STRUCT_EXPR_FIELDS_R, "struct_expr_fields", 2, $1, $2); }
        | maybe_field_inits default_field_init { $$ = treealloc(STRUCT_EXPR_FIELDS_R, "struct_expr_fields", 2, $1, $2); }
        | %empty                               { $$ = NULL; }
        ;

maybe_field_inits : field_inits {$$ = $1; }
        | field_inits COMMA {$$ = treealloc(MAYBE_FIELD_INITS_R, "maybe_field_inits", 2, $1, $2); }
        | %empty { $$ = NULL; }
        ;

field_inits : field_init                 { $$ = $1; }
        | field_inits COMMA field_init { $$ = treealloc(FIELD_INITS_R, "field_inits", 3, $1, $2, $3); }
        ;

field_init : ident                { $$ = $1; }
        | ident COLON expr       { $$ = treealloc(FIELD_INIT_R, "field_init", 3, $1, $2, $3); }
        | INTEGER_LITERAL COLON expr { $$ = treealloc(FIELD_INIT_R, "field_init", 3, $1, $2, $3); }
        ;

default_field_init : DOUBLE_DOT expr   { $$ = treealloc(DEFAULT_FIELD_INIT_R, "default_field_init", 2, $1, $2); }
        ;

block_expr : expr_match { $$ = $1; }
        | expr_if { $$ = $1; }
        | expr_if_let { $$ = $1; }
        | expr_while { $$ = $1; }
        | expr_while_let { $$ = $1; }
        | expr_loop { $$ = $1; }
        | expr_for { $$ = $1; }
        | UNSAFE block                                            { $$ = treealloc(BLOCK_EXPR_R, "block_expr", 2, $1, $2); }
        | path_expr BANG maybe_ident braces_delimited_token_trees { $$ = treealloc(BLOCK_EXPR_R, "block_expr", 4, $1, $2, $3, $4); }
        ;

full_block_expr : block_expr { $$ = $1; }
        | block_expr_dot     { $$ = $1; }
        ;

block_expr_dot : block_expr DOT path_generic_args_with_colons %prec IDENTIFIER { $$ = treealloc(BLOCK_EXPR_DOT_R, "block_expr_dot", 3, $1, $2, $3); }
        | block_expr_dot DOT path_generic_args_with_colons %prec IDENTIFIER    { $$ = treealloc(BLOCK_EXPR_DOT_R, "block_expr_dot", 3, $1, $2, $3); }
        | block_expr     DOT path_generic_args_with_colons LEFT_BRACKET maybe_expr RIGHT_BRACKET {
                $$ = treealloc(BLOCK_EXPR_DOT_R, "block_expr_dot", 6, $1, $2, $3, $4, $5, $6);
          }
        | block_expr_dot DOT path_generic_args_with_colons LEFT_BRACKET maybe_expr RIGHT_BRACKET {
                $$ = treealloc(BLOCK_EXPR_DOT_R, "block_expr_dot", 6, $1, $2, $3, $4, $5, $6);
          }
        | block_expr    DOT path_generic_args_with_colons LEFT_PAREN maybe_exprs RIGHT_PAREN {
                $$ = treealloc(BLOCK_EXPR_DOT_R, "block_expr_dot", 6, $1, $2, $3, $4, $5, $6);
          }
        | block_expr_dot DOT path_generic_args_with_colons LEFT_PAREN maybe_exprs RIGHT_PAREN { 
                $$ = treealloc(BLOCK_EXPR_DOT_R, "block_expr_dot", 6, $1, $2, $3, $4, $5, $6);
          }
        | block_expr     DOT INTEGER_LITERAL                                  { $$ = treealloc(BLOCK_EXPR_DOT_R, "block_expr_dot", 3, $1, $2, $3); }
        | block_expr_dot DOT INTEGER_LITERAL                                  { $$ = treealloc(BLOCK_EXPR_DOT_R, "block_expr_dot", 3, $1, $2, $3); }
        ;

expr_match : MATCH expr_nostruct LEFT_BRACE RIGHT_BRACE                                  { $$ = treealloc(EXPR_MATCH_R, "expr_match", 4, $1, $2, $3, $4); }
        | MATCH expr_nostruct LEFT_BRACE match_clauses                       RIGHT_BRACE { $$ = treealloc(EXPR_MATCH_R, "expr_match", 5, $1, $2, $3, $4, $5); }
        | MATCH expr_nostruct LEFT_BRACE match_clauses nonblock_match_clause RIGHT_BRACE { $$ = treealloc(EXPR_MATCH_R, "expr_match", 6, $1, $2, $3, $4, $5, $6); }
        | MATCH expr_nostruct LEFT_BRACE               nonblock_match_clause RIGHT_BRACE { $$ = treealloc(EXPR_MATCH_R, "expr_match", 5, $1, $2, $3, $4, $5); }
        ;

match_clauses : match_clause               { $$ = $1; }
        | match_clauses match_clause { $$ = treealloc(MATCH_CLAUSES_R, "match_clauses", 2, $1, $2);}
        ;

match_clause : nonblock_match_clause COMMA { $$ = treealloc(MATCH_CLAUSE_R, "match_clause", 2, $1, $2); }
        | block_match_clause { $$ = $1; }
        | block_match_clause COMMA { $$ = treealloc(MATCH_CLAUSE_R, "match_clause", 2, $1, $2); }
        ;

nonblock_match_clause : maybe_outer_attrs pats_or maybe_guard FAT_ARROW
        	        nonblock_expr  { $$ = treealloc(NONBLOCK_MATCH_CLAUSE_R, "nonblock_match_clause", 5, $1, $2, $3, $4, $5); }
        | maybe_outer_attrs pats_or maybe_guard FAT_ARROW block_expr_dot {  $$ = treealloc(NONBLOCK_MATCH_CLAUSE_R, "nonblock_match_clause", 5, $1, $2, $3, $4, $5); }
        ;

block_match_clause : maybe_outer_attrs pats_or maybe_guard FAT_ARROW block { $$ = treealloc(BLOCK_MATCH_CLAUSE_R, "block_match_clause", 5, $1, $2, $3, $4, $5); }
        | maybe_outer_attrs pats_or maybe_guard FAT_ARROW block_expr { $$ = treealloc(BLOCK_MATCH_CLAUSE_R, "block_match_clause", 5, $1, $2, $3, $4, $5); }
        ;

maybe_guard : IF expr_nostruct           { $$ = treealloc(MAYBE_GUARD_R, "maybe_guard", 2, $1, $2); }
        | %empty                     { $$ = NULL; }
        ;

expr_if : IF expr_nostruct block                              { $$ = treealloc(EXPR_IF_R, "expr_if", 3, $1, $2, $3); }
        | IF expr_nostruct block ELSE block_or_if             { $$ = treealloc(EXPR_IF_R, "expr_if", 5, $1, $2, $3, $4, $5); }
        ;

expr_if_let : IF LET pat EQUAL expr_nostruct block                  { $$ = treealloc(EXPR_IF_LET_R, "expr_if_let", 6, $1, $2, $3, $4, $5, $6); }
        | IF LET pat EQUAL expr_nostruct block ELSE block_or_if { $$ = treealloc(EXPR_IF_LET_R, "expr_if_let", 8, $1, $2, $3, $4, $5, $6, $7, $8);}
        ;

block_or_if : block { $$ = $1; }
        | expr_if { $$ = $1; }
        | expr_if_let { $$ = $1; }
        ;

expr_while : maybe_label WHILE expr_nostruct block               { $$ = treealloc(EXPR_WHILE_R, "expr_while", 4, $1, $2, $3, $4); }
        ;

expr_while_let : maybe_label WHILE LET pat EQUAL expr_nostruct block   { $$ = treealloc(EXPR_WHILE_LET_R, "expr_while_let", 7, $1, $2, $3, $4, $5, $6, $7); }
        ;

expr_loop : maybe_label LOOP block                              { $$ = treealloc(EXPR_LOOP_R, "expr_loop", 3, $1, $2, $3); }
        ;

expr_for : maybe_label FOR pat IN expr_nostruct block          { $$ = treealloc(EXPR_FOR_R, "expr_for", 6, $1, $2, $3, $4, $5, $6); }
        ;

maybe_label : lifetime COLON { $$ = treealloc(MAYBE_LABEL_R, "maybe_label", 2, $1, $2); }
        | %empty { $$ = NULL; }
        ;

let : LET pat maybe_ty_ascription maybe_init_expr SEMICOLON { $$ = treealloc(LET_R, "let", 5, $1, $2, $3, $4, $5); }
        ;

////////////////////////////////////////////////////////////////////////
// Part 5: Macros and misc. rules
////////////////////////////////////////////////////////////////////////

lit : LIT_BYTE                   { $$ = $1; }
    | CHAR_LITERAL               { $$ = $1; }
    | INTEGER_LITERAL            { $$ = $1; }
    | FLOAT_LITERAL              { $$ = $1; }
    | TRUE                       { $$ = $1; }
    | FALSE                      { $$ = $1; }
    | str                        { $$ = $1; }
    ;

str : STRING_LITERAL             { $$ = $1; }
    | STRING_LITERAL_RAW         { $$ = $1; }
    | LIT_BYTE_STR               { $$ = $1; }
    | LIT_BYTE_STR_RAW           { $$ = $1; }
    ;

maybe_ident : %empty { $$ = NULL; }
        | ident { $$ = $1; }
        ;

ident : IDENTIFIER                   { $$ = $1; }
// Weak keywords that can be used as identifiers.  Boo! Not in Irony!
        | CATCH                      { $$ = $1; }
        | DEFAULT                    { $$ = $1; }
        | UNION                      { $$ = $1; }
        ;

unpaired_token : DOUBLE_LESS_THAN       { $$ = $1; }
        | DOUBLE_GREATER_THAN           { $$ = $1; }
        | LESS_THAN_EQUAL               { $$ = $1; }
        | DOUBLE_EQUAL                  { $$ = $1; }
        | NOT_EQUAL                     { $$ = $1; }
        | GREATER_THAN_EQUAL            { $$ = $1; }
        | DOUBLE_AMPERSAND              { $$ = $1; }
        | DOUBLE_PIPE                   { $$ = $1; }
        | LARROW                        { $$ = $1; }
        | DOUBLE_LESS_THAN_EQUAL        { $$ = $1; }
        | DOUBLE_GREATER_THAN_EQUAL     { $$ = $1; }
        | MINUS_EQUAL                   { $$ = $1; }
        | AMPERSAND_EQUAL               { $$ = $1; }
        | PIPE_EQUAL                    { $$ = $1; }
        | PLUS_EQUAL                    { $$ = $1; }
        | STAR_EQUAL                    { $$ = $1; }
        | SLASH_EQUAL                   { $$ = $1; }
        | CARET_EQUAL                   { $$ = $1; }
        | PERCENT_EQUAL                 { $$ = $1; }
        | DOUBLE_DOT                    { $$ = $1; }
        | TRIPLE_DOT                    { $$ = $1; }
        | DOUBLE_COLON                  { $$ = $1; }
        | ARROW                         { $$ = $1; }
        | FAT_ARROW                     { $$ = $1; }
        | LIT_BYTE                      { $$ = $1; }
        | CHAR_LITERAL                  { $$ = $1; }
        | INTEGER_LITERAL               { $$ = $1; }
        | FLOAT_LITERAL                 { $$ = $1; }
        | STRING_LITERAL                { $$ = $1; }
        | STRING_LITERAL_RAW            { $$ = $1; }
        | LIT_BYTE_STR                  { $$ = $1; }
        | LIT_BYTE_STR_RAW              { $$ = $1; }
        | IDENTIFIER                    { $$ = $1; }
        | UNDERSCORE                    { $$ = $1; }
        | LIFETIME                      { $$ = $1; }
        | SELF                          { $$ = $1; }
        | STATIC                        { $$ = $1; }
        | ABSTRACT                      { $$ = $1; }
        | ALIGNOF                       { $$ = $1; }
        | AS                            { $$ = $1; }
        | BECOME                        { $$ = $1; }
        | BREAK                         { $$ = $1; }
        | CATCH                         { $$ = $1; }
        | CRATE                         { $$ = $1; }
        | DEFAULT                       { $$ = $1; }
        | DO                            { $$ = $1; }
        | ELSE                          { $$ = $1; }
        | ENUM                          { $$ = $1; }
        | EXTERN                        { $$ = $1; }
        | FALSE                         { $$ = $1; }
        | FINAL                         { $$ = $1; }
        | FN                            { $$ = $1; }
        | FOR                           { $$ = $1; }
        | IF                            { $$ = $1; }
        | IMPL                          { $$ = $1; }
        | IN                            { $$ = $1; }
        | LET                           { $$ = $1; }
        | LOOP                          { $$ = $1; }
        | MACRO                         { $$ = $1; }
        | MATCH                         { $$ = $1; }
        | MOD                           { $$ = $1; }
        | MOVE                          { $$ = $1; }
        | MUT                           { $$ = $1; }
        | OFFSETOF                      { $$ = $1; }
        | OVERRIDE                      { $$ = $1; }
        | PRIV                          { $$ = $1; }
        | PUB                           { $$ = $1; }
        | PURE                          { $$ = $1; }
        | REF                           { $$ = $1; }
        | RETURN                        { $$ = $1; }
        | STRUCT                        { $$ = $1; }
        | SIZEOF                        { $$ = $1; }
        | SUPER                         { $$ = $1; }
        | TRUE                          { $$ = $1; }
        | TRAIT                         { $$ = $1; }
        | TYPE                          { $$ = $1; }
        | UNION                         { $$ = $1; }
        | UNSAFE                        { $$ = $1; }
        | UNSIZED                       { $$ = $1; }
        | USE                           { $$ = $1; }
        | VIRTUAL                       { $$ = $1; }
        | WHILE                         { $$ = $1; }
        | YIELD                         { $$ = $1; }
        | CONTINUE                      { $$ = $1; }
        | PROC                          { $$ = $1; }
        | BOX                           { $$ = $1; }
        | CONST                         { $$ = $1; }
        | WHERE                         { $$ = $1; }
        | TYPEOF                        { $$ = $1; }
        | INNER_DOC_COMMENT             { $$ = $1; }
        | OUTER_DOC_COMMENT             { $$ = $1; }
        | SHEBANG                       { $$ = $1; }
        | STATIC_LIFETIME               { $$ = $1; }
        | SEMICOLON                     { $$ = $1; }
        | COMMA                         { $$ = $1; }
        | DOT                           { $$ = $1; }
        | AT                            { $$ = $1; }
        | HASH                          { $$ = $1; }
        | TILDE                         { $$ = $1; }
        | COLON                         { $$ = $1; }
        | DOLLAR                        { $$ = $1; }
        | EQUAL                         { $$ = $1; }
        | QUESTION                      { $$ = $1; }
        | BANG                          { $$ = $1; }
        | LESS_THAN                     { $$ = $1; }
        | GREATER_THAN                  { $$ = $1; }
        | MINUS                         { $$ = $1; }
        | AMPERSAND                     { $$ = $1; }
        | PIPE                          { $$ = $1; }
        | PLUS                          { $$ = $1; }
        | STAR                          { $$ = $1; }
        | SLASH                         { $$ = $1; }
        | CARET                         { $$ = $1; }
        | PERCENT                       { $$ = $1; }
        ;

token_trees : %empty                    { $$ = NULL; }
        | token_trees token_tree        { $$ = treealloc(TOKEN_TREES_R, "token_trees", 2, $1, $2); }
        ;

token_tree : delimited_token_trees      { $$ = $1; }
        | unpaired_token                { $$ = $1; }
        ;

delimited_token_trees : parens_delimited_token_trees { $$ = $1;}
        | braces_delimited_token_trees { $$ = $1; }
        | brackets_delimited_token_trees {$$ = $1; }
        ;

parens_delimited_token_trees : LEFT_PAREN token_trees RIGHT_PAREN {
                $$ = treealloc(PARENS_DELIMITED_TOKEN_TREES_R, "parens_delimited_token_trees", 3, $1, $2, $3);
        }
        ;

braces_delimited_token_trees : LEFT_BRACE token_trees RIGHT_BRACE {
                $$ = treealloc(BRACES_DELIMITED_TOKEN_TREES_R, "braces_delimited_token_trees", 3, $1, $2, $3);
        }
        ;

brackets_delimited_token_trees : LEFT_BRACKET token_trees RIGHT_BRACKET {
                $$ = treealloc(BRACKETS_DELIMITED_TOKEN_TREES_R, "brackets_delimited_token_trees", 3, $1, $2, $3);
        }
        ;

%%

const char *yyname(int sym){
        return yytname[sym-TILDE+3];
}