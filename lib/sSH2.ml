(*
 * libssh2 
 *)

type init_flag = INIT_NORMAL | INIT_NO_CRYPTO (* Don't change anything here *)

exception Init_failure

type session

external init : init_flag -> unit = "ocaml_libssh2_init"
external eXit : unit -> unit = "ocaml_libssh2_exit"


external session_init : unit -> session = "ocaml_libssh2_session_init"
external session_free : session -> unit = "ocaml_libssh2_session_free"

external base64_decode : session -> string -> string = "ocaml_libssh2_base64_decode"
