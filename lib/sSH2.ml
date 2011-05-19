(*
 * libssh2 
 *)

type init_flag = INIT_NORMAL | INIT_NO_CRYPTO (* Don't change anything here *)

exception Init_failure

external init : init_flag -> unit = "ocaml_libssh2_init"
external eXit : unit -> unit = "ocaml_libssh2_exit"
