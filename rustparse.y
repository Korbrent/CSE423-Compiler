%{
/**
 * Modified by Korbin Shelley
 * Date: February 8, 2024
 * Filename: rustparse.y
 * Description: This file contains the grammar for the Irony programming language.
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

#define YYERROR_VERBOSE
#define YYSTYPE struct node *
extern int yylex();
extern void yyerror(char const *s);
%}
%debug

%token EQUAL
%token DOUBLE_EQUAL
%token BANG
%token NOT_EQUAL
%token LESS_THAN
%token LESS_THAN_EQUAL
%token DOUBLE_LESS_THAN
%token DOUBLE_LESS_THAN_EQUAL
%token GREATER_THAN
%token GREATER_THAN_EQUAL
%token DOUBLE_GREATER_THAN
%token DOUBLE_GREATER_THAN_EQUAL
%token AMPERSAND
%token AMPERSAND_EQUAL
%token DOUBLE_AMPERSAND
%token PIPE
%token PIPE_EQUAL
%token DOUBLE_PIPE
%token CARET
%token CARET_EQUAL
%token PLUS
%token PLUS_EQUAL
%token MINUS
%token MINUS_EQUAL
%token STAR
%token STAR_EQUAL
%token SLASH
%token SLASH_EQUAL
%token PERCENT
%token PERCENT_EQUAL
%token DOT
%token DOUBLE_DOT
%token TRIPLE_DOT

// No idea what this is for
%token DOUBLE_COLON

%token HASH
%token COMMA
%token SEMICOLON
%token COLON
%token QUESTION
%token AT
%token DOLLAR
%token RIGHT_PAREN
%token LEFT_PAREN
%token RIGHT_BRACKET
%token LEFT_BRACKET
%token RIGHT_BRACE
%token LEFT_BRACE


%token ARROW
%token LARROW
%token FAT_ARROW
%token LIT_BYTE
%token CHAR_LITERAL
%token INTEGER_LITERAL
%token FLOAT_LITERAL
%token STRING_LITERAL
%token STRING_LITERAL_RAW
%token LIT_BYTE_STR
%token LIT_BYTE_STR_RAW
%token IDENTIFIER
%token UNDERSCORE
%token LIFETIME

// keywords
%token ABSTRACT
%token ALIGNOF
%token AS
%token BECOME
%token BREAK
%token CATCH
%token CRATE
%token DO
%token ELSE
%token ENUM
%token EXTERN
%token FALSE
%token FINAL
%token FN
%token FOR
%token IF
%token IMPL
%token IN
%token LET
%token LOOP
%token MACRO
%token MATCH
%token MOD
%token MOVE
%token MUT
%token OFFSETOF
%token OVERRIDE
%token PRIV
%token PUB
%token PURE
%token REF
%token RETURN
%token SELF
%token STATIC
%token SIZEOF
%token STRUCT
%token SUPER
%token UNION
%token UNSIZED
%token TRUE
%token TRAIT
%token TYPE
%token UNSAFE
%token VIRTUAL
%token YIELD
%token DEFAULT
%token USE
%token WHILE
%token CONTINUE
%token PROC
%token BOX
%token CONST
%token WHERE
%token TYPEOF
%token INNER_DOC_COMMENT
%token OUTER_DOC_COMMENT

%token SHEBANG
%token SHEBANG_LINE
%token STATIC_LIFETIME

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

%%

////////////////////////////////////////////////////////////////////////
// Part 1: Items and attributes
////////////////////////////////////////////////////////////////////////

crate   : maybe_shebang inner_attrs maybe_mod_items  {  }
        | maybe_shebang maybe_mod_items  {  }
        ;

maybe_shebang : SHEBANG_LINE
        | %empty
        ;

maybe_inner_attrs : inner_attrs
        | %empty                   { }
        ;

inner_attrs : inner_attr           {  }
        | inner_attrs inner_attr   {  }
        ;

inner_attr : SHEBANG LEFT_BRACKET meta_item RIGHT_BRACKET   {  }
        | INNER_DOC_COMMENT           {  }
        ;

maybe_outer_attrs : outer_attrs
        | %empty                   {  }
        ;

outer_attrs : outer_attr               {  }
        | outer_attrs outer_attr   {  }
        ;

outer_attr : HASH LEFT_BRACKET meta_item RIGHT_BRACKET    {  }
        | OUTER_DOC_COMMENT        {  }
        ;

meta_item : ident                      {  }
        | ident EQUAL lit              {  }
        | ident LEFT_PAREN meta_seq RIGHT_PAREN     {  }
        | ident LEFT_PAREN meta_seq COMMA RIGHT_PAREN {  }
        ;

meta_seq : %empty                   {  }
        | meta_item                {  }
        | meta_seq COMMA meta_item   {  }
        ;

maybe_mod_items : mod_items
        | %empty             {  }
        ;

mod_items : mod_item                               {  }
        | mod_items mod_item                     {  }
        ;

attrs_and_vis : maybe_outer_attrs visibility           {  }
        ;

mod_item : attrs_and_vis item    {  }
        ;

// items that can appear outside of a fn block
item : stmt_item
        | item_macro
        ;

// items that can appear in "stmts"
stmt_item : item_static
        | item_const
        | item_type
        | block_item
        | view_item
        ;

item_static : STATIC ident COLON ty EQUAL expr SEMICOLON  {  }
        | STATIC MUT ident COLON ty EQUAL expr SEMICOLON  {  }
        ;

item_const : CONST ident COLON ty EQUAL expr SEMICOLON    {  }
        ;

item_macro : path_expr BANG maybe_ident parens_delimited_token_trees SEMICOLON  {  }
        | path_expr BANG maybe_ident braces_delimited_token_trees      {  }
        | path_expr BANG maybe_ident brackets_delimited_token_trees SEMICOLON{  }
        ;

view_item : use_item
        | extern_fn_item
        | EXTERN CRATE ident SEMICOLON                      {  }
        | EXTERN CRATE ident AS ident SEMICOLON             {  }
        ;

extern_fn_item : EXTERN maybe_abi item_fn             {  }
        ;

use_item : USE view_path SEMICOLON                          {  }
        ;

view_path : path_no_types_allowed                                    {  }
        | path_no_types_allowed DOUBLE_COLON LEFT_BRACE                RIGHT_BRACE     {  }
        |                       DOUBLE_COLON LEFT_BRACE                RIGHT_BRACE     {  }
        | path_no_types_allowed DOUBLE_COLON LEFT_BRACE idents_or_self RIGHT_BRACE     {  }
        |                       DOUBLE_COLON LEFT_BRACE idents_or_self RIGHT_BRACE     {  }
        | path_no_types_allowed DOUBLE_COLON LEFT_BRACE idents_or_self COMMA RIGHT_BRACE {  }
        |                       DOUBLE_COLON LEFT_BRACE idents_or_self COMMA RIGHT_BRACE {  }
        | path_no_types_allowed DOUBLE_COLON STAR                        {  }
        |                       DOUBLE_COLON STAR                        {  }
        |                               STAR                        {  }
        |                               LEFT_BRACE                RIGHT_BRACE     {  }
        |                               LEFT_BRACE idents_or_self RIGHT_BRACE     {  }
        |                               LEFT_BRACE idents_or_self COMMA RIGHT_BRACE {  }
        | path_no_types_allowed AS ident                           {  }
        ;

block_item : item_fn
        | item_unsafe_fn
        | item_mod
        | item_foreign_mod          {  }
        | item_struct
        | item_enum
        | item_union
        | item_trait
        | item_impl
        ;

maybe_ty_ascription : COLON ty_sum {  }
        | %empty {  }
        ;

maybe_init_expr : EQUAL expr {  }
        | %empty   {  }
        ;

// structs
item_struct : STRUCT ident generic_params maybe_where_clause struct_decl_args {

          }
        | STRUCT ident generic_params struct_tuple_args maybe_where_clause SEMICOLON{

          }
        | STRUCT ident generic_params maybe_where_clause SEMICOLON {

          }
        ;

struct_decl_args : LEFT_BRACE struct_decl_fields RIGHT_BRACE         {  }
        | LEFT_BRACE struct_decl_fields COMMA RIGHT_BRACE              {  }
        ;

struct_tuple_args : LEFT_PAREN struct_tuple_fields RIGHT_PAREN       {  }
        | LEFT_PAREN struct_tuple_fields COMMA RIGHT_PAREN             {  }
        ;

struct_decl_fields : struct_decl_field                {  }
        | struct_decl_fields COMMA struct_decl_field    {  }
        | %empty                                      {  }
        ;

struct_decl_field : attrs_and_vis ident COLON ty_sum    {  }
        ;

struct_tuple_fields : struct_tuple_field              {  }
        | struct_tuple_fields COMMA struct_tuple_field  {  }
        | %empty                                      {  }
        ;

struct_tuple_field : attrs_and_vis ty_sum             {  }
        ;

// enums
item_enum : ENUM ident generic_params maybe_where_clause LEFT_BRACE enum_defs RIGHT_BRACE {
          }
        | ENUM ident generic_params maybe_where_clause LEFT_BRACE enum_defs COMMA RIGHT_BRACE {
          }
        ;

enum_defs : enum_def             {  }
        | enum_defs COMMA enum_def {  }
        | %empty                 {  }
        ;

enum_def : attrs_and_vis ident enum_args {  }
        ;

enum_args : LEFT_BRACE struct_decl_fields RIGHT_BRACE     {  }
        | LEFT_BRACE struct_decl_fields COMMA RIGHT_BRACE {  }
        | LEFT_PAREN maybe_ty_sums RIGHT_PAREN          {  }
        | EQUAL expr                       {  }
        | %empty                         {  }
        ;

// unions
item_union : UNION ident generic_params maybe_where_clause LEFT_BRACE struct_decl_fields RIGHT_BRACE     {  }
        | UNION ident generic_params maybe_where_clause LEFT_BRACE struct_decl_fields COMMA RIGHT_BRACE {  }
        ;

item_mod : MOD ident SEMICOLON                                {  }
        | MOD ident LEFT_BRACE maybe_mod_items RIGHT_BRACE             {  }
        | MOD ident LEFT_BRACE inner_attrs maybe_mod_items RIGHT_BRACE {  }
        ;

item_foreign_mod : EXTERN maybe_abi LEFT_BRACE maybe_foreign_items RIGHT_BRACE {  }
        | EXTERN maybe_abi LEFT_BRACE inner_attrs maybe_foreign_items RIGHT_BRACE {  }
        ;

maybe_abi : str
        | %empty {  }
        ;

maybe_foreign_items : foreign_items
        | %empty {  }
        ;

foreign_items : foreign_item               {  }
        | foreign_items foreign_item {  }
        ;

foreign_item : attrs_and_vis STATIC item_foreign_static {  }
        | attrs_and_vis item_foreign_fn            {  }
        | attrs_and_vis UNSAFE item_foreign_fn     {  }
        ;

item_foreign_static
        : maybe_mut ident COLON ty SEMICOLON               {  }
        ;

item_foreign_fn
        : FN ident generic_params fn_decl_allow_variadic maybe_where_clause SEMICOLON
          {  }
        ;

fn_decl_allow_variadic : fn_params_allow_variadic ret_ty {  }
        ;

fn_params_allow_variadic : LEFT_PAREN RIGHT_PAREN     {  }
        | LEFT_PAREN params RIGHT_PAREN               {  }
        | LEFT_PAREN params COMMA RIGHT_PAREN           {  }
        | LEFT_PAREN params COMMA TRIPLE_DOT RIGHT_PAREN {  }
        ;

visibility : PUB      {  }
        | %empty   {  }
        ;

idents_or_self : ident_or_self                    {  }
        | idents_or_self AS ident          {  }
        | idents_or_self COMMA ident_or_self {  }
        ;

ident_or_self : ident
        | SELF  {  }
        ;

item_type : TYPE ident generic_params maybe_where_clause EQUAL ty_sum SEMICOLON  {  }
        ;

for_sized : FOR QUESTION ident {  }
        | FOR ident QUESTION {  }
        | %empty        {  }
        ;

item_trait : maybe_unsafe TRAIT ident generic_params for_sized
             maybe_ty_param_bounds maybe_where_clause LEFT_BRACE maybe_trait_items RIGHT_BRACE
          {

          }
        ;

maybe_trait_items : trait_items
        | %empty {  }
        ;

trait_items : trait_item               {  }
        | trait_items trait_item       {  }
        ;

trait_item : trait_const
        | trait_type
        | trait_method
        | maybe_outer_attrs item_macro {  }
        ;

trait_const : maybe_outer_attrs CONST ident maybe_ty_ascription
              maybe_const_default SEMICOLON {  }
        ;

maybe_const_default : EQUAL expr {  }
        | %empty   {  }
        ;

trait_type : maybe_outer_attrs TYPE ty_param SEMICOLON {  }
        ;

maybe_unsafe : UNSAFE {  }
        | %empty {  }
        ;

maybe_default_maybe_unsafe : DEFAULT UNSAFE {  }
        | DEFAULT        {  }
        |         UNSAFE {  }
        | %empty {  }
        ;

trait_method : type_method {  }
        | method      {  }
        ;

type_method : maybe_outer_attrs maybe_unsafe FN ident generic_params
              fn_decl_with_self_allow_anon_params maybe_where_clause SEMICOLON
          {

          }
        | maybe_outer_attrs CONST maybe_unsafe FN ident generic_params
          fn_decl_with_self_allow_anon_params maybe_where_clause SEMICOLON {

          }
        | maybe_outer_attrs maybe_unsafe EXTERN maybe_abi FN ident
          generic_params fn_decl_with_self_allow_anon_params
           maybe_where_clause SEMICOLON {

          }
        ;

method : maybe_outer_attrs maybe_unsafe FN ident generic_params
         fn_decl_with_self_allow_anon_params maybe_where_clause
          inner_attrs_and_block {

         }
        | maybe_outer_attrs CONST maybe_unsafe FN ident generic_params
          fn_decl_with_self_allow_anon_params maybe_where_clause
          inner_attrs_and_block {

          }
        | maybe_outer_attrs maybe_unsafe EXTERN maybe_abi FN ident
          generic_params fn_decl_with_self_allow_anon_params
          maybe_where_clause inner_attrs_and_block {

          }
        ;

impl_method : attrs_and_vis maybe_default maybe_unsafe FN ident generic_params
              fn_decl_with_self maybe_where_clause inner_attrs_and_block {

          }
        | attrs_and_vis maybe_default CONST maybe_unsafe FN ident
          generic_params fn_decl_with_self maybe_where_clause
          inner_attrs_and_block {

          }
        | attrs_and_vis maybe_default maybe_unsafe EXTERN maybe_abi FN ident
          generic_params fn_decl_with_self maybe_where_clause
          inner_attrs_and_block {

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

          }
        | maybe_default_maybe_unsafe IMPL generic_params LEFT_PAREN ty RIGHT_PAREN
          maybe_where_clause LEFT_BRACE maybe_inner_attrs maybe_impl_items RIGHT_BRACE {

          }
        | maybe_default_maybe_unsafe IMPL generic_params trait_ref FOR ty_sum maybe_where_clause LEFT_BRACE maybe_inner_attrs maybe_impl_items RIGHT_BRACE {

          }
        | maybe_default_maybe_unsafe IMPL generic_params BANG trait_ref FOR
           ty_sum maybe_where_clause LEFT_BRACE maybe_inner_attrs maybe_impl_items RIGHT_BRACE
          {

          }
        | maybe_default_maybe_unsafe IMPL generic_params trait_ref FOR DOUBLE_DOT
          LEFT_BRACE RIGHT_BRACE {

          }
        | maybe_default_maybe_unsafe IMPL generic_params BANG trait_ref FOR
          DOUBLE_DOT LEFT_BRACE RIGHT_BRACE {

          }
        ;

maybe_impl_items : impl_items
        | %empty {  }
        ;

impl_items : impl_item               {  }
        | impl_item impl_items    {  }
        ;

impl_item : impl_method
        | attrs_and_vis item_macro {  }
        | impl_const
        | impl_type
        ;

maybe_default : DEFAULT {  }
        | %empty {  }
        ;

impl_const : attrs_and_vis maybe_default item_const {  }
        ;

impl_type : attrs_and_vis maybe_default TYPE ident generic_params
            EQUAL ty_sum SEMICOLON  {  }
        ;

item_fn : FN ident generic_params fn_decl maybe_where_clause
          inner_attrs_and_block {

          }
        | CONST FN ident generic_params fn_decl maybe_where_clause
           inner_attrs_and_block {

          }
        ;

item_unsafe_fn : UNSAFE FN ident generic_params fn_decl maybe_where_clause
                 inner_attrs_and_block {

          }
        | CONST UNSAFE FN ident generic_params fn_decl maybe_where_clause
          inner_attrs_and_block {

          }
        | UNSAFE EXTERN maybe_abi FN ident generic_params fn_decl
           maybe_where_clause inner_attrs_and_block {

          }
        ;

fn_decl : fn_params ret_ty   {  }
        ;

fn_decl_with_self : fn_params_with_self ret_ty   {  }
        ;

fn_decl_with_self_allow_anon_params : fn_anon_params_with_self ret_ty   {  }
        ;

fn_params : LEFT_PAREN maybe_params RIGHT_PAREN  {  }
        ;

fn_anon_params : LEFT_PAREN anon_param anon_params_allow_variadic_tail RIGHT_PAREN {  }
        | LEFT_PAREN RIGHT_PAREN                                            {  }
        ;

fn_params_with_self : LEFT_PAREN maybe_mut SELF maybe_ty_ascription
        	       maybe_comma_params RIGHT_PAREN              {  }
        | LEFT_PAREN AMPERSAND maybe_mut SELF maybe_ty_ascription maybe_comma_params RIGHT_PAREN {
          }
        | LEFT_PAREN AMPERSAND lifetime maybe_mut SELF maybe_ty_ascription
           maybe_comma_params RIGHT_PAREN {  }
        | LEFT_PAREN maybe_params RIGHT_PAREN    {  }
        ;

fn_anon_params_with_self : LEFT_PAREN maybe_mut SELF maybe_ty_ascription
        maybe_comma_anon_params RIGHT_PAREN              {  }
        | LEFT_PAREN AMPERSAND maybe_mut SELF maybe_ty_ascription maybe_comma_anon_params
          RIGHT_PAREN          {  }
        | LEFT_PAREN AMPERSAND lifetime maybe_mut SELF maybe_ty_ascription
          maybe_comma_anon_params RIGHT_PAREN {  }
        | LEFT_PAREN maybe_anon_params RIGHT_PAREN   {  }
        ;

maybe_params : params
        | params COMMA
        | %empty  {  }
        ;

params  : param                {  }
        | params COMMA param     {  }
        ;

param   : pat COLON ty_sum   {  }
        ;

inferrable_params : inferrable_param                       {  }
        | inferrable_params COMMA inferrable_param {  }
        ;

inferrable_param : pat maybe_ty_ascription {  }
        ;

maybe_comma_params : COMMA            {  }
        | COMMA params     {  }
        | COMMA params COMMA {  }
        | %empty         {  }
        ;

maybe_comma_anon_params : COMMA                 {  }
        | COMMA anon_params     {  }
        | COMMA anon_params COMMA {  }
        | %empty              {  }
        ;

maybe_anon_params : anon_params
        | anon_params COMMA
        | %empty      {  }
        ;

anon_params : anon_param                 {  }
        | anon_params COMMA anon_param {  }
        ;

// anon means it's allowed to be anonymous (type-only), but it can
// still have a name
anon_param : named_arg COLON ty   {  }
        | ty
        ;

anon_params_allow_variadic_tail : COMMA TRIPLE_DOT          {  }
        | COMMA anon_param anon_params_allow_variadic_tail {  }
        | %empty                                         {  }
        ;

named_arg : ident
        | UNDERSCORE        {  }
        | AMPERSAND ident         {  }
        | AMPERSAND UNDERSCORE    {  }
        | DOUBLE_AMPERSAND ident      {  }
        | DOUBLE_AMPERSAND UNDERSCORE {  }
        | MUT ident         {  }
        ;

ret_ty : ARROW BANG         {  }
        | ARROW ty          {  }
        | %prec IDENTIFIER %empty {  }
        ;

generic_params : LESS_THAN GREATER_THAN                             {  }
        | LESS_THAN lifetimes GREATER_THAN                   {  }
        | LESS_THAN lifetimes COMMA GREATER_THAN               {  }
        | LESS_THAN lifetimes DOUBLE_GREATER_THAN                   {  }
        | LESS_THAN lifetimes COMMA DOUBLE_GREATER_THAN               {  }
        | LESS_THAN lifetimes COMMA ty_params GREATER_THAN     {  }
        | LESS_THAN lifetimes COMMA ty_params COMMA GREATER_THAN {  }
        | LESS_THAN lifetimes COMMA ty_params DOUBLE_GREATER_THAN     {  }
        | LESS_THAN lifetimes COMMA ty_params COMMA DOUBLE_GREATER_THAN {  }
        | LESS_THAN ty_params GREATER_THAN                   {  }
        | LESS_THAN ty_params COMMA GREATER_THAN               {  }
        | LESS_THAN ty_params DOUBLE_GREATER_THAN                   {  }
        | LESS_THAN ty_params COMMA DOUBLE_GREATER_THAN               {  }
        | %empty                              {  }
        ;

maybe_where_clause : %empty                              {  }
        | where_clause
        ;

where_clause : WHERE where_predicates              {  }
        | WHERE where_predicates COMMA          {  }
        ;

where_predicates : where_predicate                      {  }
        | where_predicates COMMA where_predicate {  }
        ;

where_predicate : maybe_for_lifetimes lifetime COLON bounds    {  }
        | maybe_for_lifetimes ty COLON ty_param_bounds {  }
        ;

maybe_for_lifetimes : FOR LESS_THAN lifetimes GREATER_THAN {  }
        | %prec FORTYPE %empty  {  }
        ;

ty_params : ty_param               {  }
        | ty_params COMMA ty_param {  }
        ;

// A path with no type parameters; e.g. `foo::bar::Baz`
//
// These show up in 'use' view-items, because these are processed
// without respect to types.
path_no_types_allowed : ident                               {  }
        | DOUBLE_COLON ident                       {  }
        | SELF                                {  }
        | DOUBLE_COLON SELF                        {  }
        | SUPER                               {  }
        | DOUBLE_COLON SUPER                       {  }
        | path_no_types_allowed DOUBLE_COLON ident {  }
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
          }
        | %prec IDENTIFIER  ident generic_args {
          }
        | %prec IDENTIFIER ident LEFT_PAREN maybe_ty_sums RIGHT_PAREN ret_ty {
          }
        | %prec IDENTIFIER path_generic_args_without_colons DOUBLE_COLON ident {
          }
        | %prec IDENTIFIER path_generic_args_without_colons DOUBLE_COLON ident
          generic_args                 {  }
        | %prec IDENTIFIER path_generic_args_without_colons DOUBLE_COLON ident
          LEFT_PAREN maybe_ty_sums RIGHT_PAREN ret_ty {  }
        ;

generic_args : LESS_THAN generic_values GREATER_THAN   {  }
        | LESS_THAN generic_values DOUBLE_GREATER_THAN   {  }
        | LESS_THAN generic_values GREATER_THAN_EQUAL    {  }
        | LESS_THAN generic_values DOUBLE_GREATER_THAN_EQUAL {  }
// If generic_args starts with "<<", the first arg must be a
// TyQualifiedPath because that's the only type that can start with a
// '<'. This rule parses that as the first ty_sum and then continues
// with the rest of generic_values.
        | DOUBLE_LESS_THAN ty_qualified_path_and_generic_values GREATER_THAN   {  }
        | DOUBLE_LESS_THAN ty_qualified_path_and_generic_values DOUBLE_GREATER_THAN   {  }
        | DOUBLE_LESS_THAN ty_qualified_path_and_generic_values GREATER_THAN_EQUAL    {  }
        | DOUBLE_LESS_THAN ty_qualified_path_and_generic_values DOUBLE_GREATER_THAN_EQUAL {  }
        ;

generic_values : maybe_ty_sums_and_or_bindings {  }
        ;

maybe_ty_sums_and_or_bindings : ty_sums
        | ty_sums COMMA
        | ty_sums COMMA bindings {  }
        | bindings
        | bindings COMMA
        | %empty               {  }
        ;

maybe_bindings : COMMA bindings {  }
        | %empty       {  }
        ;

////////////////////////////////////////////////////////////////////////
// Part 2: Patterns
////////////////////////////////////////////////////////////////////////

pat : UNDERSCORE                                      {  }
        | AMPERSAND pat                                         {  }
        | AMPERSAND MUT pat                                     {  }
        | DOUBLE_AMPERSAND pat                                      {  }
        | LEFT_PAREN RIGHT_PAREN                                         {  }
        | LEFT_PAREN pat_tup RIGHT_PAREN                                 {  }
        | LEFT_BRACKET pat_vec RIGHT_BRACKET                                 {  }
        | lit_or_path
        | lit_or_path TRIPLE_DOT lit_or_path               {  }
        | path_expr LEFT_BRACE pat_struct RIGHT_BRACE                    {  }
        | path_expr LEFT_PAREN RIGHT_PAREN                               {  }
        | path_expr LEFT_PAREN pat_tup RIGHT_PAREN                       {  }
        | path_expr BANG maybe_ident delimited_token_trees {  }
        | binding_mode ident                              {  }
        |              ident AT pat                      {  }
        | binding_mode ident AT pat                      {  }
        | BOX pat                                         {  }
        | LESS_THAN ty_sum maybe_as_trait_ref GREATER_THAN DOUBLE_COLON ident {  }
        | DOUBLE_LESS_THAN ty_sum maybe_as_trait_ref GREATER_THAN DOUBLE_COLON ident
           maybe_as_trait_ref GREATER_THAN DOUBLE_COLON ident {

          }
        ;

pats_or : pat              {  }
        | pats_or PIPE pat  {  }
        ;

binding_mode : REF         {  }
        | REF MUT     {  }
        | MUT         {  }
        ;

lit_or_path : path_expr    {  }
        | lit          {  }
        | MINUS lit      {  }
        ;

pat_field :                  ident        {  }
        |     binding_mode ident        {  }
        | BOX              ident        {  }
        | BOX binding_mode ident        {  }
        |              ident COLON pat    {  }
        | binding_mode ident COLON pat    {  }
        |        INTEGER_LITERAL COLON pat    {  }
        ;

pat_fields : pat_field                  {  }
        | pat_fields COMMA pat_field   {  }
        ;

pat_struct : pat_fields                 {  }
        | pat_fields COMMA             {  }
        | pat_fields COMMA DOUBLE_DOT      {  }
        | DOUBLE_DOT                     {  }
        | %empty                     {  }
        ;

pat_tup : pat_tup_elts                                  {  }
        | pat_tup_elts                             COMMA  {  }
        | pat_tup_elts     DOUBLE_DOT                       {  }
        | pat_tup_elts COMMA DOUBLE_DOT                       {  }
        | pat_tup_elts     DOUBLE_DOT COMMA pat_tup_elts      {  }
        | pat_tup_elts     DOUBLE_DOT COMMA pat_tup_elts COMMA  {  }
        | pat_tup_elts COMMA DOUBLE_DOT COMMA pat_tup_elts      {  }
        | pat_tup_elts COMMA DOUBLE_DOT COMMA pat_tup_elts COMMA  {  }
        |                  DOUBLE_DOT COMMA pat_tup_elts      {  }
        |                  DOUBLE_DOT COMMA pat_tup_elts COMMA  {  }
        |                  DOUBLE_DOT                       {  }
        ;

pat_tup_elts : pat                    {  }
        | pat_tup_elts COMMA pat        {  }
        ;

pat_vec : pat_vec_elts                                  {  }
        | pat_vec_elts                             COMMA  {  }
        | pat_vec_elts     DOUBLE_DOT                       {  }
        | pat_vec_elts COMMA DOUBLE_DOT                       {  }
        | pat_vec_elts     DOUBLE_DOT COMMA pat_vec_elts      {  }
        | pat_vec_elts     DOUBLE_DOT COMMA pat_vec_elts COMMA  {  }
        | pat_vec_elts COMMA DOUBLE_DOT COMMA pat_vec_elts      {  }
        | pat_vec_elts COMMA DOUBLE_DOT COMMA pat_vec_elts COMMA  {  }
        |                  DOUBLE_DOT COMMA pat_vec_elts      {  }
        |                  DOUBLE_DOT COMMA pat_vec_elts COMMA  {  }
        |                  DOUBLE_DOT                       {  }
        | %empty                                        {  }
        ;

pat_vec_elts : pat                    {  }
        | pat_vec_elts COMMA pat   {  }
        ;

////////////////////////////////////////////////////////////////////////
// Part 3: Types
////////////////////////////////////////////////////////////////////////

ty : ty_prim
        | ty_closure
        | LESS_THAN ty_sum maybe_as_trait_ref GREATER_THAN DOUBLE_COLON ident {  }
        | DOUBLE_LESS_THAN ty_sum maybe_as_trait_ref GREATER_THAN DOUBLE_COLON ident
          maybe_as_trait_ref GREATER_THAN DOUBLE_COLON ident {  }
        | LEFT_PAREN ty_sums RIGHT_PAREN                                 {  }
        | LEFT_PAREN ty_sums COMMA RIGHT_PAREN                             {  }
        | LEFT_PAREN RIGHT_PAREN                                         {  }
        ;

ty_prim : %prec IDENTIFIER path_generic_args_without_colons    {  }
        | %prec IDENTIFIER DOUBLE_COLON path_generic_args_without_colons {  }
        | %prec IDENTIFIER SELF DOUBLE_COLON path_generic_args_without_colons {  }
        | %prec IDENTIFIER path_generic_args_without_colons BANG maybe_ident
          delimited_token_trees         {  }
        | %prec IDENTIFIER DOUBLE_COLON path_generic_args_without_colons BANG
          maybe_ident delimited_token_trees {  }
        | BOX ty                                                    {  }
        | STAR maybe_mut_or_const ty                                 {  }
        | AMPERSAND ty                                                    {  }
        | AMPERSAND MUT ty                                                {  }
        | DOUBLE_AMPERSAND ty                                                 {  }
        | DOUBLE_AMPERSAND MUT ty                                             {  }
        | AMPERSAND lifetime maybe_mut ty                                 {  }
        | DOUBLE_AMPERSAND lifetime maybe_mut ty                              {  }
        | LEFT_BRACKET ty RIGHT_BRACKET                                                {  }
        | LEFT_BRACKET ty COMMA DOUBLE_DOT expr RIGHT_BRACKET                                {  }
        | LEFT_BRACKET ty SEMICOLON expr RIGHT_BRACKET                                       {  }
        | TYPEOF LEFT_PAREN expr RIGHT_PAREN                                       {  }
        | UNDERSCORE                                                {  }
        | ty_bare_fn
        | for_in_type
        ;

ty_bare_fn :                      FN ty_fn_decl {  }
        | UNSAFE                  FN ty_fn_decl {  }
        |        EXTERN maybe_abi FN ty_fn_decl {  }
        | UNSAFE EXTERN maybe_abi FN ty_fn_decl {  }
        ;

ty_fn_decl : generic_params fn_anon_params ret_ty {  }
        ;

ty_closure : UNSAFE PIPE anon_params PIPE maybe_bounds ret_ty {  }
        |           PIPE anon_params PIPE maybe_bounds ret_ty {  }
        |    UNSAFE DOUBLE_PIPE maybe_bounds ret_ty                {  }
        |           DOUBLE_PIPE maybe_bounds ret_ty                {  }
        ;

for_in_type : FOR LESS_THAN maybe_lifetimes GREATER_THAN for_in_type_suffix {  }
        ;

for_in_type_suffix : ty_bare_fn
        | trait_ref
        | ty_closure
        ;

maybe_mut : MUT              {  }
        | %prec MUT %empty {  }
        ;

maybe_mut_or_const : MUT    {  }
        | CONST  {  }
        | %empty {  }
        ;

ty_qualified_path_and_generic_values : ty_qualified_path maybe_bindings {
  
          }
        | ty_qualified_path COMMA ty_sums maybe_bindings {
  
          }
        ;

ty_qualified_path : ty_sum AS trait_ref GREATER_THAN DOUBLE_COLON ident           {  }
        | ty_sum AS trait_ref GREATER_THAN DOUBLE_COLON ident PLUS ty_param_bounds {  }
        ;

maybe_ty_sums : ty_sums
        | ty_sums COMMA
        | %empty {  }
        ;

ty_sums : ty_sum             {  }
        | ty_sums COMMA ty_sum {  }
        ;

ty_sum : ty_sum_elt            {  }
        | ty_sum PLUS ty_sum_elt {  }
        ;

ty_sum_elt : ty
        | lifetime
        ;

ty_prim_sum : ty_prim_sum_elt                 {  }
        | ty_prim_sum PLUS ty_prim_sum_elt {  }
        ;

ty_prim_sum_elt : ty_prim
        | lifetime
        ;

maybe_ty_param_bounds : COLON ty_param_bounds {  }
        | %empty              {  }
        ;

ty_param_bounds : boundseq
        | %empty {  }
        ;

boundseq : polybound
        | boundseq PLUS polybound {  }
        ;

polybound : FOR LESS_THAN maybe_lifetimes GREATER_THAN bound {  }
        | bound
        | QUESTION FOR LESS_THAN maybe_lifetimes GREATER_THAN bound {  }
        | QUESTION bound {  }
        ;

bindings : binding              {  }
        | bindings COMMA binding {  }
        ;

binding : ident EQUAL ty {  }
        ;

ty_param : ident maybe_ty_param_bounds maybe_ty_default           {  }
        | ident QUESTION ident maybe_ty_param_bounds maybe_ty_default {  }
        ;

maybe_bounds : %prec SHIFTPLUS COLON bounds             {  }
        | %prec SHIFTPLUS %empty {  }
        ;

bounds : bound            {  }
        | bounds PLUS bound {  }
        ;

bound : lifetime
        | trait_ref
        ;

maybe_ltbounds : %prec SHIFTPLUS COLON ltbounds       {  }
        | %empty             {  }
        ;

ltbounds : lifetime              {  }
        | ltbounds PLUS lifetime {  }
        ;

maybe_ty_default : EQUAL ty_sum {  }
        | %empty     {  }
        ;

maybe_lifetimes : lifetimes
        | lifetimes COMMA
        | %empty {  }
        ;

lifetimes : lifetime_and_bounds               {  }
        | lifetimes COMMA lifetime_and_bounds {  }
        ;

lifetime_and_bounds : LIFETIME maybe_ltbounds         {  }
        | STATIC_LIFETIME                 {  }
        ;

lifetime : LIFETIME         {  }
        | STATIC_LIFETIME  {  }
        ;

trait_ref : %prec IDENTIFIER path_generic_args_without_colons
        | %prec IDENTIFIER DOUBLE_COLON path_generic_args_without_colons {  }
        ;

////////////////////////////////////////////////////////////////////////
// Part 4: Blocks, statements, and expressions
////////////////////////////////////////////////////////////////////////

inner_attrs_and_block : LEFT_BRACE maybe_inner_attrs maybe_stmts RIGHT_BRACE        {  }
        ;

block : LEFT_BRACE maybe_stmts RIGHT_BRACE                          {  }
        ;

maybe_stmts : stmts
        | stmts nonblock_expr {  }
        | nonblock_expr
        | %empty              {  }
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

stmts : stmt           {  }
        | stmts stmt     {  }
        ;

stmt : maybe_outer_attrs let     {  }
        |                 stmt_item
        |             PUB stmt_item {  }
        | outer_attrs     stmt_item {  }
        | outer_attrs PUB stmt_item {  }
        | full_block_expr
        | maybe_outer_attrs block   {  }
        |             nonblock_expr SEMICOLON
        | outer_attrs nonblock_expr SEMICOLON {  }
        | SEMICOLON                   {  }
        ;

maybe_exprs : exprs
        | exprs COMMA
        | %empty {  }
        ;

maybe_expr : expr
        | %empty {  }
        ;

exprs : expr                                         {  }
        | exprs COMMA expr                             {  }
        ;

path_expr : path_generic_args_with_colons
        | DOUBLE_COLON path_generic_args_with_colons      {  }
        | SELF DOUBLE_COLON path_generic_args_with_colons {  }
        ;

// A path with a lifetime and type parameters with double colons before
// the type parameters; e.g. `foo::bar::<'a>::Baz::<T>`
//
// These show up in expr context, in order to disambiguate from "less-than"
// expressions.
path_generic_args_with_colons : ident                        {  }
        | SUPER                                              {  }
        | path_generic_args_with_colons DOUBLE_COLON ident        {  }
        | path_generic_args_with_colons DOUBLE_COLON SUPER        {  }
        | path_generic_args_with_colons DOUBLE_COLON generic_args {  }
        ;

// the braces-delimited macro is a block_expr so it doesn't appear here
macro_expr : path_expr BANG maybe_ident parens_delimited_token_trees   {  }
        | path_expr BANG maybe_ident brackets_delimited_token_trees {  }
        ;

nonblock_expr : lit                                                     {  }
        | %prec IDENTIFIER path_expr                                         {  }
        | SELF                                                          {  }
        | macro_expr                                                    {  }
        | path_expr LEFT_BRACE struct_expr_fields RIGHT_BRACE                          {  }
        | nonblock_expr QUESTION                                             {  }
        | nonblock_expr DOT path_generic_args_with_colons               {  }
        | nonblock_expr DOT INTEGER_LITERAL                                 {  }
        | nonblock_expr LEFT_BRACKET maybe_expr RIGHT_BRACKET                              {  }
        | nonblock_expr LEFT_PAREN maybe_exprs RIGHT_PAREN                             {  }
        | LEFT_BRACKET vec_expr RIGHT_BRACKET                                              {  }
        | LEFT_PAREN maybe_exprs RIGHT_PAREN                                           {  }
        | CONTINUE                                                      {  }
        | CONTINUE lifetime                                             {  }
        | RETURN                                                        {  }
        | RETURN expr                                                   {  }
        | BREAK                                                         {  }
        | BREAK lifetime                                                {  }
        | YIELD                                                         {  }
        | YIELD expr                                                    {  }
        | nonblock_expr EQUAL expr                                        {  }
        | nonblock_expr DOUBLE_LESS_THAN_EQUAL expr                                      {  }
        | nonblock_expr DOUBLE_GREATER_THAN_EQUAL expr                                      {  }
        | nonblock_expr MINUS_EQUAL expr                                    {  }
        | nonblock_expr AMPERSAND_EQUAL expr                                      {  }
        | nonblock_expr PIPE_EQUAL expr                                       {  }
        | nonblock_expr PLUS_EQUAL expr                                     {  }
        | nonblock_expr STAR_EQUAL expr                                     {  }
        | nonblock_expr SLASH_EQUAL expr                                    {  }
        | nonblock_expr CARET_EQUAL expr                                    {  }
        | nonblock_expr PERCENT_EQUAL expr                                  {  }
        | nonblock_expr DOUBLE_PIPE expr                                       {  }
        | nonblock_expr DOUBLE_AMPERSAND expr                                     {  }
        | nonblock_expr DOUBLE_EQUAL expr                                       {  }
        | nonblock_expr NOT_EQUAL expr                                         {  }
        | nonblock_expr LESS_THAN expr                                        {  }
        | nonblock_expr GREATER_THAN expr                                        {  }
        | nonblock_expr LESS_THAN_EQUAL expr                                         {  }
        | nonblock_expr GREATER_THAN_EQUAL expr                                         {  }
        | nonblock_expr PIPE expr                                        {  }
        | nonblock_expr CARET expr                                        {  }
        | nonblock_expr AMPERSAND expr                                        {  }
        | nonblock_expr DOUBLE_LESS_THAN expr                                        {  }
        | nonblock_expr DOUBLE_GREATER_THAN expr                                        {  }
        | nonblock_expr PLUS expr                                        {  }
        | nonblock_expr MINUS expr                                        {  }
        | nonblock_expr STAR expr                                        {  }
        | nonblock_expr SLASH expr                                        {  }
        | nonblock_expr PERCENT expr                                        {  }
        | nonblock_expr DOUBLE_DOT                                          {  }
        | nonblock_expr DOUBLE_DOT expr                                     {  }
        |               DOUBLE_DOT expr                                     {  }
        |               DOUBLE_DOT                                          {  }
        | nonblock_expr AS ty                                           {  }
        | nonblock_expr COLON ty                                          {  }
        | BOX expr                                                      {  }
        | expr_qualified_path
        | nonblock_prefix_expr
        ;

expr : lit                                                 {  }
     | %prec IDENTIFIER path_expr                               {  }
     | SELF                                                {  }
     | macro_expr                                          {  }
     | path_expr LEFT_BRACE struct_expr_fields RIGHT_BRACE                {  }
     | expr QUESTION                                            {  }
     | expr DOT path_generic_args_with_colons              {  }
     | expr DOT INTEGER_LITERAL                                {  }
     | expr LEFT_BRACKET maybe_expr RIGHT_BRACKET                             {  }
     | expr LEFT_PAREN maybe_exprs RIGHT_PAREN                            {  }
     | LEFT_PAREN maybe_exprs RIGHT_PAREN                                 {  }
     | LEFT_BRACKET vec_expr RIGHT_BRACKET                                    {  }
     | CONTINUE                                            {  }
     | CONTINUE ident                                      {  }
     | RETURN                                              {  }
     | RETURN expr                                         {  }
     | BREAK                                               {  }
     | BREAK ident                                         {  }
     | YIELD                                               {  }
     | YIELD expr                                          {  }
     | expr EQUAL expr                                       {  }
     | expr DOUBLE_LESS_THAN_EQUAL expr                                     {  }
     | expr DOUBLE_GREATER_THAN_EQUAL expr                                     {  }
     | expr MINUS_EQUAL expr                                   {  }
     | expr AMPERSAND_EQUAL expr                                     {  }
     | expr PIPE_EQUAL expr                                      {  }
     | expr PLUS_EQUAL expr                                    {  }
     | expr STAR_EQUAL expr                                    {  }
     | expr SLASH_EQUAL expr                                   {  }
     | expr CARET_EQUAL expr                                   {  }
     | expr PERCENT_EQUAL expr                                 {  }
     | expr DOUBLE_PIPE expr                                      {  }
     | expr DOUBLE_AMPERSAND expr                                    {  }
     | expr DOUBLE_EQUAL expr                                      {  }
     | expr NOT_EQUAL expr                                        {  }
     | expr LESS_THAN expr                                       {  }
     | expr GREATER_THAN expr                                       {  }
     | expr LESS_THAN_EQUAL expr                                        {  }
     | expr GREATER_THAN_EQUAL expr                                        {  }
     | expr PIPE expr                                       {  }
     | expr CARET expr                                       {  }
     | expr AMPERSAND expr                                       {  }
     | expr DOUBLE_LESS_THAN expr                                       {  }
     | expr DOUBLE_GREATER_THAN expr                                       {  }
     | expr PLUS expr                                       {  }
     | expr MINUS expr                                       {  }
     | expr STAR expr                                       {  }
     | expr SLASH expr                                       {  }
     | expr PERCENT expr                                       {  }
     | expr DOUBLE_DOT                                         {  }
     | expr DOUBLE_DOT expr                                    {  }
     |      DOUBLE_DOT expr                                    {  }
     |      DOUBLE_DOT                                         {  }
     | expr AS ty                                          {  }
     | expr COLON ty                                         {  }
     | BOX expr                                            {  }
     | expr_qualified_path
     | block_expr
     | block
     | nonblock_prefix_expr
     ;

expr_nostruct : lit                                                 {  }
        | %prec IDENTIFIER path_expr                                     {  }
        | SELF                                                {  }
        | macro_expr                                          {  }
        | expr_nostruct QUESTION                                   {  }
        | expr_nostruct DOT path_generic_args_with_colons     {  }
        | expr_nostruct DOT INTEGER_LITERAL                       {  }
        | expr_nostruct LEFT_BRACKET maybe_expr RIGHT_BRACKET                    {  }
        | expr_nostruct LEFT_PAREN maybe_exprs RIGHT_PAREN                   {  }
        | LEFT_BRACKET vec_expr RIGHT_BRACKET                                    {  }
        | LEFT_PAREN maybe_exprs RIGHT_PAREN                                 {  }
        | CONTINUE                                            {  }
        | CONTINUE ident                                      {  }
        | RETURN                                              {  }
        | RETURN expr                                         {  }
        | BREAK                                               {  }
        | BREAK ident                                         {  }
        | YIELD                                               {  }
        | YIELD expr                                          {  }
        | expr_nostruct EQUAL expr_nostruct                     {  }
        | expr_nostruct DOUBLE_LESS_THAN_EQUAL expr_nostruct                   {  }
        | expr_nostruct DOUBLE_GREATER_THAN_EQUAL expr_nostruct                   {  }
        | expr_nostruct MINUS_EQUAL expr_nostruct                 {  }
        | expr_nostruct AMPERSAND_EQUAL expr_nostruct                   {  }
        | expr_nostruct PIPE_EQUAL expr_nostruct                    {  }
        | expr_nostruct PLUS_EQUAL expr_nostruct                  {  }
        | expr_nostruct STAR_EQUAL expr_nostruct                  {  }
        | expr_nostruct SLASH_EQUAL expr_nostruct                 {  }
        | expr_nostruct CARET_EQUAL expr_nostruct                 {  }
        | expr_nostruct PERCENT_EQUAL expr_nostruct               {  }
        | expr_nostruct DOUBLE_PIPE expr_nostruct                    {  }
        | expr_nostruct DOUBLE_AMPERSAND expr_nostruct                  {  }
        | expr_nostruct DOUBLE_EQUAL expr_nostruct                    {  }
        | expr_nostruct NOT_EQUAL expr_nostruct                      {  }
        | expr_nostruct LESS_THAN expr_nostruct                     {  }
        | expr_nostruct GREATER_THAN expr_nostruct                     {  }
        | expr_nostruct LESS_THAN_EQUAL expr_nostruct                      {  }
        | expr_nostruct GREATER_THAN_EQUAL expr_nostruct                      {  }
        | expr_nostruct PIPE expr_nostruct                     {  }
        | expr_nostruct CARET expr_nostruct                     {  }
        | expr_nostruct AMPERSAND expr_nostruct                     {  }
        | expr_nostruct DOUBLE_LESS_THAN expr_nostruct                     {  }
        | expr_nostruct DOUBLE_GREATER_THAN expr_nostruct                     {  }
        | expr_nostruct PLUS expr_nostruct                     {  }
        | expr_nostruct MINUS expr_nostruct                     {  }
        | expr_nostruct STAR expr_nostruct                     {  }
        | expr_nostruct SLASH expr_nostruct                     {  }
        | expr_nostruct PERCENT expr_nostruct                     {  }
        | expr_nostruct DOUBLE_DOT               %prec RANGE      {  }
        | expr_nostruct DOUBLE_DOT expr_nostruct                  {  }
        |               DOUBLE_DOT expr_nostruct                  {  }
        |               DOUBLE_DOT                                {  }
        | expr_nostruct AS ty                                 {  }
        | expr_nostruct COLON ty                                {  }
        | BOX expr                                            {  }
        | expr_qualified_path
        | block_expr
        | block
        | nonblock_prefix_expr_nostruct
        ;

nonblock_prefix_expr_nostruct : MINUS expr_nostruct                         {  }
        | BANG expr_nostruct                         {  }
        | STAR expr_nostruct                         {  }
        | AMPERSAND maybe_mut expr_nostruct               {  }
        | DOUBLE_AMPERSAND maybe_mut expr_nostruct            {  }
        | lambda_expr_nostruct
        | MOVE lambda_expr_nostruct                 {  }
        ;

nonblock_prefix_expr : MINUS expr                         {  }
        | BANG expr                         {  }
        | STAR expr                         {  }
        | AMPERSAND maybe_mut expr               {  }
        | DOUBLE_AMPERSAND maybe_mut expr            {  }
        | lambda_expr
        | MOVE lambda_expr                 {  }
        ;

expr_qualified_path : LESS_THAN ty_sum maybe_as_trait_ref GREATER_THAN DOUBLE_COLON ident
        	       maybe_qpath_params {
  
          }
        | DOUBLE_LESS_THAN ty_sum maybe_as_trait_ref GREATER_THAN DOUBLE_COLON ident
          maybe_as_trait_ref GREATER_THAN DOUBLE_COLON ident {

          }
        | DOUBLE_LESS_THAN ty_sum maybe_as_trait_ref GREATER_THAN DOUBLE_COLON ident
          generic_args maybe_as_trait_ref GREATER_THAN DOUBLE_COLON ident {
  
          }
        | DOUBLE_LESS_THAN ty_sum maybe_as_trait_ref GREATER_THAN DOUBLE_COLON ident
          maybe_as_trait_ref GREATER_THAN DOUBLE_COLON ident generic_args {

          }
        | DOUBLE_LESS_THAN ty_sum maybe_as_trait_ref GREATER_THAN DOUBLE_COLON ident
          generic_args maybe_as_trait_ref GREATER_THAN DOUBLE_COLON ident generic_args {
  
          }
        ;

maybe_qpath_params : DOUBLE_COLON generic_args {  }
        | %empty               {  }
        ;

maybe_as_trait_ref : AS trait_ref {  }
        | %empty       {  }
        ;

lambda_expr : %prec LAMBDA DOUBLE_PIPE ret_ty expr                          {  }
        | %prec LAMBDA PIPE PIPE ret_ty expr                           {  }
        | %prec LAMBDA PIPE inferrable_params PIPE ret_ty expr         {  }
        | %prec LAMBDA PIPE inferrable_params DOUBLE_PIPE lambda_expr_no_first_bar {  }
        ;

lambda_expr_no_first_bar : %prec LAMBDA PIPE ret_ty expr                {  }
        | %prec LAMBDA inferrable_params PIPE ret_ty expr               {  }
        | %prec LAMBDA inferrable_params DOUBLE_PIPE lambda_expr_no_first_bar {  }
        ;

lambda_expr_nostruct : %prec LAMBDA DOUBLE_PIPE expr_nostruct                 {  }
        | %prec LAMBDA PIPE PIPE ret_ty expr_nostruct                    {  }
        | %prec LAMBDA PIPE inferrable_params PIPE expr_nostruct         {  }
        | %prec LAMBDA PIPE inferrable_params DOUBLE_PIPE
          lambda_expr_nostruct_no_first_bar {  }
        ;

lambda_expr_nostruct_no_first_bar : %prec LAMBDA PIPE ret_ty expr_nostruct {  }
        | %prec LAMBDA inferrable_params PIPE ret_ty expr_nostruct         {  }
        | %prec LAMBDA inferrable_params DOUBLE_PIPE
          lambda_expr_nostruct_no_first_bar {  }
        ;

vec_expr : maybe_exprs
        | exprs SEMICOLON expr {  }
        ;

struct_expr_fields : field_inits
        | field_inits COMMA
        | maybe_field_inits default_field_init {  }
        | %empty                               {  }
        ;

maybe_field_inits : field_inits
        | field_inits COMMA
        | %empty {  }
        ;

field_inits : field_init                 {  }
        | field_inits COMMA field_init {  }
        ;

field_init : ident                {  }
        | ident COLON expr       {  }
        | INTEGER_LITERAL COLON expr {  }
        ;

default_field_init : DOUBLE_DOT expr   {  }
        ;

block_expr : expr_match
        | expr_if
        | expr_if_let
        | expr_while
        | expr_while_let
        | expr_loop
        | expr_for
        | UNSAFE block                                           {  }
        | path_expr BANG maybe_ident braces_delimited_token_trees {  }
        ;

full_block_expr : block_expr
        | block_expr_dot
        ;

block_expr_dot : block_expr DOT path_generic_args_with_colons %prec IDENTIFIER {  }
        | block_expr_dot DOT path_generic_args_with_colons %prec IDENTIFIER    {  }
        | block_expr     DOT path_generic_args_with_colons LEFT_BRACKET maybe_expr RIGHT_BRACKET {
          }
        | block_expr_dot DOT path_generic_args_with_colons LEFT_BRACKET maybe_expr RIGHT_BRACKET {
          }
        | block_expr    DOT path_generic_args_with_colons LEFT_PAREN maybe_exprs RIGHT_PAREN {
          }
        | block_expr_dot DOT path_generic_args_with_colons LEFT_PAREN maybe_exprs RIGHT_PAREN {  }
        | block_expr     DOT INTEGER_LITERAL                                  {  }
        | block_expr_dot DOT INTEGER_LITERAL                                  {  }
        ;

expr_match : MATCH expr_nostruct LEFT_BRACE RIGHT_BRACE                                  {  }
        | MATCH expr_nostruct LEFT_BRACE match_clauses                       RIGHT_BRACE {  }
        | MATCH expr_nostruct LEFT_BRACE match_clauses nonblock_match_clause RIGHT_BRACE {  }
        | MATCH expr_nostruct LEFT_BRACE               nonblock_match_clause RIGHT_BRACE {  }
        ;

match_clauses : match_clause               {  }
        | match_clauses match_clause {  }
        ;

match_clause : nonblock_match_clause COMMA
        | block_match_clause
        | block_match_clause COMMA
        ;

nonblock_match_clause : maybe_outer_attrs pats_or maybe_guard FAT_ARROW
        	        nonblock_expr  {  }
        | maybe_outer_attrs pats_or maybe_guard FAT_ARROW block_expr_dot {  }
        ;

block_match_clause : maybe_outer_attrs pats_or maybe_guard FAT_ARROW block {  }
        | maybe_outer_attrs pats_or maybe_guard FAT_ARROW block_expr {  }
        ;

maybe_guard : IF expr_nostruct           {  }
        | %empty                     {  }
        ;

expr_if : IF expr_nostruct block                              {  }
        | IF expr_nostruct block ELSE block_or_if             {  }
        ;

expr_if_let : IF LET pat EQUAL expr_nostruct block                  {  }
        | IF LET pat EQUAL expr_nostruct block ELSE block_or_if {  }
        ;

block_or_if : block
        | expr_if
        | expr_if_let
        ;

expr_while : maybe_label WHILE expr_nostruct block               {  }
        ;

expr_while_let : maybe_label WHILE LET pat EQUAL expr_nostruct block   {  }
        ;

expr_loop : maybe_label LOOP block                              {  }
        ;

expr_for : maybe_label FOR pat IN expr_nostruct block          {  }
        ;

maybe_label : lifetime COLON
        | %empty {  }
        ;

let : LET pat maybe_ty_ascription maybe_init_expr SEMICOLON {  }
        ;

////////////////////////////////////////////////////////////////////////
// Part 5: Macros and misc. rules
////////////////////////////////////////////////////////////////////////

lit : LIT_BYTE                   {  }
    | CHAR_LITERAL                   {  }
    | INTEGER_LITERAL                {  }
    | FLOAT_LITERAL                  {  }
    | TRUE                       {  }
    | FALSE                      {  }
    | str
    ;

str : STRING_LITERAL                    {  }
    | STRING_LITERAL_RAW                {  }
    | LIT_BYTE_STR               {  }
    | LIT_BYTE_STR_RAW           {  }
    ;

maybe_ident : %empty {  }
        | ident
        ;

ident : IDENTIFIER                      {  }
// Weak keywords that can be used as identifiers.  Boo! Not in Irony!
        | CATCH                      {  }
        | DEFAULT                    {  }
        | UNION                      {  }
        ;

unpaired_token : DOUBLE_LESS_THAN                        {  }
        | DOUBLE_GREATER_THAN                        {  }
        | LESS_THAN_EQUAL                         {  }
        | DOUBLE_EQUAL                       {  }
        | NOT_EQUAL                         {  }
        | GREATER_THAN_EQUAL                         {  }
        | DOUBLE_AMPERSAND                     {  }
        | DOUBLE_PIPE                       {  }
        | LARROW                     {  }
        | DOUBLE_LESS_THAN_EQUAL                      {  }
        | DOUBLE_GREATER_THAN_EQUAL                      {  }
        | MINUS_EQUAL                    {  }
        | AMPERSAND_EQUAL                      {  }
        | PIPE_EQUAL                       {  }
        | PLUS_EQUAL                     {  }
        | STAR_EQUAL                     {  }
        | SLASH_EQUAL                    {  }
        | CARET_EQUAL                    {  }
        | PERCENT_EQUAL                  {  }
        | DOUBLE_DOT                     {  }
        | TRIPLE_DOT                  {  }
        | DOUBLE_COLON                    {  }
        | ARROW                     {  }
        | FAT_ARROW                  {  }
        | LIT_BYTE                   {  }
        | CHAR_LITERAL                   {  }
        | INTEGER_LITERAL                {  }
        | FLOAT_LITERAL                  {  }
        | STRING_LITERAL                    {  }
        | STRING_LITERAL_RAW                {  }
        | LIT_BYTE_STR               {  }
        | LIT_BYTE_STR_RAW           {  }
        | IDENTIFIER                      {  }
        | UNDERSCORE                 {  }
        | LIFETIME                   {  }
        | SELF                       {  }
        | STATIC                     {  }
        | ABSTRACT                   {  }
        | ALIGNOF                    {  }
        | AS                         {  }
        | BECOME                     {  }
        | BREAK                      {  }
        | CATCH                      {  }
        | CRATE                      {  }
        | DEFAULT                    {  }
        | DO                         {  }
        | ELSE                       {  }
        | ENUM                       {  }
        | EXTERN                     {  }
        | FALSE                      {  }
        | FINAL                      {  }
        | FN                         {  }
        | FOR                        {  }
        | IF                         {  }
        | IMPL                       {  }
        | IN                         {  }
        | LET                        {  }
        | LOOP                       {  }
        | MACRO                      {  }
        | MATCH                      {  }
        | MOD                        {  }
        | MOVE                       {  }
        | MUT                        {  }
        | OFFSETOF                   {  }
        | OVERRIDE                   {  }
        | PRIV                       {  }
        | PUB                        {  }
        | PURE                       {  }
        | REF                        {  }
        | RETURN                     {  }
        | STRUCT                     {  }
        | SIZEOF                     {  }
        | SUPER                      {  }
        | TRUE                       {  }
        | TRAIT                      {  }
        | TYPE                       {  }
        | UNION                      {  }
        | UNSAFE                     {  }
        | UNSIZED                    {  }
        | USE                        {  }
        | VIRTUAL                    {  }
        | WHILE                      {  }
        | YIELD                      {  }
        | CONTINUE                   {  }
        | PROC                       {  }
        | BOX                        {  }
        | CONST                      {  }
        | WHERE                      {  }
        | TYPEOF                     {  }
        | INNER_DOC_COMMENT          {  }
        | OUTER_DOC_COMMENT          {  }
        | SHEBANG                    {  }
        | STATIC_LIFETIME            {  }
        | SEMICOLON                        {  }
        | COMMA                        {  }
        | DOT                        {  }
        | AT                        {  }
        | HASH                        {  }
        | '~'                        {  }
        | COLON                        {  }
        | DOLLAR                        {  }
        | EQUAL                        {  }
        | QUESTION                        {  }
        | BANG                        {  }
        | LESS_THAN                        {  }
        | GREATER_THAN                        {  }
        | MINUS                        {  }
        | AMPERSAND                        {  }
        | PIPE                        {  }
        | PLUS                        {  }
        | STAR                        {  }
        | SLASH                        {  }
        | CARET                        {  }
        | PERCENT                        {  }
        ;

token_trees : %empty                     {  }
        | token_trees token_tree     {  }
        ;

token_tree : delimited_token_trees
        | unpaired_token         {  }
        ;

delimited_token_trees : parens_delimited_token_trees
        | braces_delimited_token_trees
        | brackets_delimited_token_trees
        ;

parens_delimited_token_trees : LEFT_PAREN token_trees RIGHT_PAREN {
  
        }
        ;

braces_delimited_token_trees : LEFT_BRACE token_trees RIGHT_BRACE {
  
        }
        ;

brackets_delimited_token_trees : LEFT_BRACKET token_trees RIGHT_BRACKET {

        }
        ;
