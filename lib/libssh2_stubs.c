#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>

#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/fail.h>

#include <libssh2.h>

/*
 * libssh2_init()
 */

value ocaml_libssh2_init (value ocaml_flag) {
  CAMLparam1 (ocaml_flag);
  int rc ;
  int flag ;

  flag = Int_val (ocaml_flag); 

  printf ("init flag is %d\n", flag) ;

  rc = libssh2_init (LIBSSH2_INIT_NO_CRYPTO);

  if (rc) caml_failwith("libssh2_init returned a non-zero rc") ;
  
  CAMLreturn (Val_unit);
}

