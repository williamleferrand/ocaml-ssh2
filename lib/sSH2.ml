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

external session_startup : session -> Unix.file_descr -> [ `Ok | `Eagain ] = "ocaml_libssh2_session_startup"
external session_disconnect : session -> string -> [ `Ok | `Eagain ] = "ocaml_libssh2_session_disconnect" 

external userauth_password : session -> string -> string -> [ `Authenticated | `Forbidden | `Eagain ] = "ocaml_libssh2_userauth_password"

external channel_open_session : session -> [ `Channel of channel | `Eagain ] = "ocaml_libssh2_channel_open_session"
external channel_free : channel -> unit = "ocaml_libssh2_channel_free"

external channel_setenv : channel -> string -> string -> unit = "ocaml_libssh2_channel_setenv"
external channel_request_pty : channel -> unit = "ocaml_libssh2_channel_request_pty"


external channel_exec : channel -> string -> unit = "ocaml_libssh2_channel_exec"
external channel_read : channel -> string -> int -> [ `Eagain | `Read of int ] = "ocaml_libssh2_channel_read"

external channel_shell : channel -> [ `Eagain | `Ready ] = "ocaml_libssh2_channel_shell"
external channel_write : channel -> string -> int -> [ `Eagain | `Wrote of int ] = "ocaml_libssh2_channel_write"

external channel_send_eof : channel -> unit = "ocaml_libssh2_channel_send_eof"
external channel_eof : channel -> unit = "ocaml_libssh2_channel_eof"
external channel_flush : channel -> unit = "ocaml_libssh2_channel_flush"

external set_session_blocking : session -> bool -> unit = "ocaml_libssh2_session_set_blocking" 
external set_channel_blocking : channel -> bool -> unit = "ocaml_libssh2_channel_set_blocking" 


