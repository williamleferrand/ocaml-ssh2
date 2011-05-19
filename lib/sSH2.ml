(*
 * libssh2 
 *)

(* Not a lwt interface yet ;( *)

type init_flag = INIT_NORMAL | INIT_NO_CRYPTO (* Don't change anything here *)

exception Init_failure

type session
type channel

external init : init_flag -> unit = "ocaml_libssh2_init"
external eXit : unit -> unit = "ocaml_libssh2_exit"


external session_init : unit -> session = "ocaml_libssh2_session_init"
external session_free : session -> unit = "ocaml_libssh2_session_free"

external base64_decode : session -> string -> string = "ocaml_libssh2_base64_decode"

external session_startup : session -> Unix.file_descr -> unit = "ocaml_libssh2_session_startup"
external session_disconnect : session -> string -> unit = "ocaml_libssh2_session_disconnect" 

external userauth_password : session -> string -> string -> bool = "ocaml_libssh2_userauth_password"

external channel_open_session : session -> channel = "ocaml_libssh2_channel_open_session"
external channel_free : channel -> unit = "ocaml_libssh2_channel_free"
